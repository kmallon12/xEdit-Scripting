{
  Run on a quest object to import dialogue from a text file into branches/topics/infos for that quest.
  The goal is to automate the step of literally copying text into the Creation Kit. Steps like linking
  dialogue, setting branch type, entering conditions, etc... are not part of this script.
  
  Each row of the text file corresponds to one segment of a topic info. Must be |-delimited as:
    Speaker Name|Prompt|Response|Acting Note|Emotion|Value|Branch|Topic|Info #|Segment #
  "Info #" is the number of the topic info inside the topic, and "Segment #" is the response number
  inside the topic info.
	
  Make sure your prompts/responses don't have "|" in them. Some fields (e.g. Branch and Acting Note)
  may be left blank. 
  
  Additionally, requires a ";"-delimited text file that maps the speaker name to that NPC's form ID:
	Speaker Name;Form ID
  "Speaker Name" should match what is used in the imported dialogue text file.
  It's up to the user if you want this to be actual name, something shorthand, editor ID, etc... All
  that matters is that it is the same between the two maps.
  
  Topic and branch prefixes may be set as script constants.
  
  Only handles Player Dialogue and Hello, Goodbye, Idle, and SharedInfo misc topics. Anything else gets
  put into the SharedInfo topic; just move it manually afterwards.
  
  Requires a default TopicInfo that will be copied for new infos. This should a single empty response
  and a GetIsID condition run on the subject and equal to one. Set the plugin and form ID for this info
  as script constants.
}
unit ImportDialogue;

var
	dialogueMap, branchList, topicList, infoStackList, speakerMap: TStringList;
	defaultInfo, defaultTopic, defaultBranch: IInterface;
	lastKey, hello, goodbye, idle, sharedInfo: string;

const	 // change these as needed
	refPlugin = 2;
	refInfoID = '01000805';
	topicPrefix = 'Abek';
	branchPrefix = 'Abek';

// Called before processing
function Initialize: integer;
var
	dlgOpen: TOpenDialog;
begin
	AddMessage(IntToStr(wbVersionNumber));
	
	// create dialogue map object
	dialogueMap := TStringList.Create;
	dialogueMap.NameValueSeparator := '|';
	
	// import dialogue map: select file name to import from
	dlgOpen := TOpenDialog.Create(nil);
	dlgOpen.Title := 'Select the dialogue to import.';
	dlgOpen.Filter := 'Text files (*.txt)|*.txt';
	if dlgOpen.Execute then begin
	  dialogueMap.LoadFromFile(dlgOpen.FileName);
	end;
	
	// create speaker map object
	speakerMap := TStringList.Create;
	speakerMap.NameValueSeparator := ';';
	// import speaker map: 
	dlgOpen.Title := 'Select the speaker map to import.';
	dlgOpen.Filter := 'Text files (*.txt)|*.txt';
	if dlgOpen.Execute then begin
	  speakerMap.LoadFromFile(dlgOpen.FileName);
	end;
	dlgOpen.Free;
	
	// nothing to import
	if dialogueMap.Count = 0 then begin
	  dialogueMap.Free;
	  AddMessage('no dialougue found');
	  Result := 1;
	  Exit;
	end else if speakerMap.Count = 0 then begin
	  speakerMap.Free;
	  AddMessage('no speakers found');
	  Result := 1;
	  Exit;
	
	end;

	// create branch/topic/info list objects
	branchList := TStringList.Create;
	branchList.NameValueSeparator := ';';

	topicList := TStringList.Create;
	topicList.NameValueSeparator := ';';

	infoStackList := TStringList.Create;
	infoStackList.NameValueSeparator := ';';

	// grab a generic info to copy from.
	// this should only have one condition, a GetIsID condition run on the subject and equal to one.
	defaultInfo := RecordByFormID(FileByIndex(refPlugin),refInfoID,false);
	defaultTopic := LinksTo(ElementByName(defaultInfo,'Topic'));
	defaultBranch := LinksTo(ElementByPath(defaultTopic,'BNAM'));
	
	// xEdit changed how some records are listed in 4.1.5.b
	if wbVersionNumber > 67175681 then begin
		hello := 'Hello';
		goodbye := 'GoodBye';
		idle := 'Idle';
		sharedInfo := 'SharedInfo';
	end else begin
		hello := 'HELO';
		goodbye := 'GBYE';
		idle := 'IDLE';
		sharedInfo := 'IDAT';
	end;
end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
var
	myQuest, myBranch, myTopic, myInfo, conditions, condition, responses, response, f: IInterface;
	fullLine, speaker, prompt, dialogue, actingnote, emotion, value, branch, topic, info, segment, key: string;
	branchKey, topicKey, pnamKey: string;
	i, k, oldCount: integer;
begin
	if Signature(e) <> 'QUST' then exit;

	f := GetFile(e);
	
	if topicPrefix = '' then topicPrefix := GetElementEditValues(e,'EDID');
	if branchPrefix = '' then branchPrefix := GetElementEditValues(e,'EDID');

	// iterate through lines
	for i := 0 to dialogueMap.Count-1 do begin
		
		// get components
		speaker := dialogueMap.Names[i];
		
		fullLine := dialogueMap.ValueFromIndex[i];
		k := pos('|',fullLine);
		prompt := copy(fullLine,1,k-1);
		
		fullLine := copy(fullLine,k+1,length(fullLine));
		k := pos('|',fullLine);
		dialogue := copy(fullLine,1,k-1);
		
		fullLine := copy(fullLine,k+1,length(fullLine));
		k := pos('|',fullLine);
		actingnote := copy(fullLine,1,k-1);
		
		fullLine := copy(fullLine,k+1,length(fullLine));
		k := pos('|',fullLine);
		emotion := copy(fullLine,1,k-1);
		
		fullLine := copy(fullLine,k+1,length(fullLine));
		k := pos('|',fullLine);
		value := copy(fullLine,1,k-1);
		
		fullLine := copy(fullLine,k+1,length(fullLine));
		k := pos('|',fullLine);
		branch := copy(fullLine,1,k-1);
		
		fullLine := copy(fullLine,k+1,length(fullLine));
		k := pos('|',fullLine);
		topic := copy(fullLine,1,k-1);
		
		fullLine := copy(fullLine,k+1,length(fullLine));
		k := pos('|',fullLine);
		info := copy(fullLine,1,k-1);
		
		segment := copy(fullLine,k+1,length(fullLine));
		
		// check if adding segment or new info
		key := topic + info;
		if key = lastKey then begin
			// same info, add new response
			oldCount := GetElementNativeValues(response,'TRDT\Response Number');
			response := ElementAssign(responses,HighInteger,response,false);
			SetElementNativeValues(response,'TRDT\Response Number',oldCount+1);
			SetElementEditValues(response,'TRDT\Emotion Type',emotion);
			SetElementEditValues(response,'TRDT\Emotion Value',value);
			SetElementEditValues(response,'NAM1',dialogue);
			SetElementEditValues(response,'NAM2',actingnote);
		end else begin
			// create new info
			myInfo := wbCopyElementToFile(defaultInfo, f, True, True);
			
			// set prompt & response
			SetElementEditValues(myInfo,'RNAM',prompt);
			responses := ElementByPath(myInfo,'Responses');
			response := ElementByIndex(responses,0);
			SetElementNativeValues(response,'TRDT\Response Number',oldCount+1);
			SetElementEditValues(response,'TRDT\Emotion Type',emotion);
			SetElementEditValues(response,'TRDT\Emotion Value',value);
			SetElementEditValues(response,'NAM1',dialogue);
			SetElementEditValues(response,'NAM2',actingnote);
			
			//set speaker
			conditions := ElementByPath(myInfo,'Conditions');
			condition := ElementByIndex(conditions,0);
			SetElementEditValues(condition,'CTDA\Referenceable Object',speakerMap.Values[speaker]);
			
			// get topic
			topicKey := topicList.Values[topic];
			if topicKey = '' then begin
				// create new topic
				myTopic := wbCopyElementToFile(defaultTopic, f, True, True);
				SetElementEditValues(myInfo,'Topic',GetEditValue(myTopic));
				SetElementEditValues(myTopic,'EDID',topicPrefix + topic);
				SetElementEditValues(myTopic,'QNAM',GetEditValue(e));
				
				// generate topic text
				SetElementEditValues(myTopic,'FULL',StringReplace(topic,'Topic','',[true, true]));
				
				// get branch
				branchKey := branchList.Values[branch];
				if branch = '' then begin
					// branch field is empty --> misc dialogue, not player dialogue
					Remove(ElementByPath(myTopic,'BNAM'));
					// assign subtypes
					SetElementEditValues(e,'DATA - Data\Category','Miscellaneous');
					if (pos('Hello',topic)>0) or (pos('Greeting',topic)>0) then begin
						SetElementEditValues(myTopic,'SNAM',hello);
						SetElementEditValues(myTopic,'DATA - Data\Subtype','Hello');
					end else if pos('Idle',topic)>0 then begin
						SetElementEditValues(myTopic,'SNAM',idle);
						SetElementEditValues(myTopic,'DATA - Data\Subtype','Idle');
					end else if pos('Goodbye',topic)>0 then begin
						SetElementEditValues(myTopic,'SNAM',goodbye);
						SetElementEditValues(myTopic,'DATA - Data\Subtype','GoodBye');
					end else begin
						SetElementEditValues(myTopic,'SNAM',sharedInfo);
						SetElementEditValues(myTopic,'DATA - Data\Subtype','SharedInfo');
						SetElementEditValues(myTopic,'FULL','Shared Info');
					end;
				end else if branchKey = '' then begin
					// create new branch
					myBranch := wbCopyElementToFile(defaultBranch, f, True, True);
					SetElementEditValues(myTopic,'BNAM',GetEditValue(myBranch));
					SetElementEditValues(myBranch,'EDID',branchPrefix + branch);
					SetElementEditValues(myBranch,'QNAM',GetEditValue(e));
					SetElementEditValues(myBranch,'SNAM',GetEditValue(myTopic));
					branchList.Add(branch + ';' + GetEditValue(myBranch));
				end else begin
					// add to existing branch
					SetElementEditValues(myTopic,'BNAM',branchKey);
				end;
				
				topicList.Add(topic + ';' + GetEditValue(myTopic));
			end else begin
				// add to existing topic
				SetElementEditValues(myInfo,'Topic',topicKey);
			end;
			
			// update pnam
			pnamKey := infoStackList.Values[topic];
			if pnamKey = '' then begin
				SetElementEditValues(myInfo,'PNAM','00000000');
				infoStackList.Add(topic + ';' + GetEditValue(myInfo));
			end else begin
				SetElementEditValues(myInfo,'PNAM',pnamKey);
				infoStackList.Values[topic] := GetEditValue(myInfo);
			end;
			
		end;
		
		lastKey := key;
		
	end;

end;

// Called after processing
// You can remove it if script doesn't require finalization code
function Finalize: integer;
begin
	dialogueMap.Free;
	branchList.Free;
	topicList.Free;
	infoStackList.Free;
	speakerMap.Free;
end;

end.