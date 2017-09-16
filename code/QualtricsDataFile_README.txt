Procedure for removing PPI from downloaded Qualtrics data file:

The Qualtrics data file contains protected personal information (email and IP address). We can remove these columns using Excel. When Excel loads a CSV file, however, it converts text strings of numbers to a numeric variable, which interferes with subsequent processing of the file. The procedure below describes how to load the data from a CSV file into Excel and then save it again without converting cell contents to numbers.


In Excel, open a new sheet. On the Data ribbon click "Get External Data From Text". Select your CSV file then click "Open". Click "Next". Uncheck "Tab", place a check mark next to "Comma", then click "Next". Click anywhere on the first column. While holding the shift key drag the slider across until you can click in the last column, then release the shift key. Click the "text" radio button then click "Finish"

All columns will be imported as text, just as they were in the CSV file.