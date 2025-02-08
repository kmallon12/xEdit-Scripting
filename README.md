## Dialogue Import Tool
The goal is to automate the step of literally copying text into the Creation Kit. Steps like linking dialogue, setting branch type, entering conditions, etc... are not part of this script.

Place `Skywind - Import dialogue for quest.pas` into your `\xEdit\Edit Scripts\` folder. Locate or create a template topic info that the script will copy when creating new topic infos, and enter its Form ID in the `const` section. Likewise enter that info's plugin number. This template TopicInfo should a single blank response and a GetIsID condition run on the subject and equal to one. Right now, the script can only set conditions for single speakers. Conditions for groups of speakers (such as faction, voicetype, and so on) should be set manually.

This script will use two selectable text files, one that contains all dialogue to import and another that maps speaker name to form ID.

Each row of the dialogue text file corresponds to one segment of a topic info. Must be `|`-delimited as:  
`Speaker Name|Prompt|Response|Acting Note|Emotion|Value|Branch|Topic|Info #|Segment #`  
where "Info #" is the number of the topic info inside the topic, and "Segment #" is the response number inside the topic info. It is important that the dialogue you are importing does not use `|` anywhere. Some fields (e.g. Branch and Acting Note) may be left blank. 

The speaker map should be a ";"-delimited text file that maps the speaker names to those NPCs' form IDs:  
`Speaker Name;Form ID`  
Each row is a different speaker. "Speaker Name" should match what is used in the imported dialogue text file. It's up to the user if you want this to be actual name, something shorthand, editor ID, etc... All that matters is that it is the same between the two text files.

Load the plugin into which to import dialogue, and run the script on the quest object that will hold the imported dialogue. The script will then create the branches, topics, and infos listed in the text file. Only new branches/topics will be used; the script will not find and add to existing branches. If that is needed, import first them move manually in the Creation Kit.

Topic and branch prefixes may be set as script constants.

This script only handles Player Dialogue and Hello, Goodbye, Idle, and SharedInfo misc topics. Anything else gets put into the SharedInfo topic; just move it manually afterwards.

An example plugin and text files are provided. Open the plugin in SSEEdit and run the script on DialogueAbekLendrian. Select `Example Dialogue for Import.txt` as the dialogue to import and `Example Speaker Map.txt` as the speaker map. Additionally, a spreadsheet is provided for more easily generating the contents of the dialogue import file. Skywind's writer's use a spreadsheet similar to this for writing dialogue, though I believe most other projects use documents rather than spreadsheets.
