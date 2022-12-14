#!/bin/bash
ns="off"
gsd="off"
ts=$3
outFolder="RunFiles/Run_"$ts

fastaFile=$(ls -1 $outFolder/GenomeAssembly_Files/Combined_Fasta_sequences.fasta)
summaryFile=$(ls -1 $outFolder/GenomeAssembly_Files/SampleSummary.txt)
#gsdMeta=$(ls -1 $outFolder/GISAID_Files/Epi*Metadata.csv)
#gsdFasta=$(ls -1 $outFolder/GISAID_Files/Epi*fasta)
#nsDir=$(ls -1 $outFolder/Nextstrain_Files | grep -v clade)
#ncFile=$(ls -1 $outFolder/Nextstrain_Files/nextclade.tsv)
printf "<b>The pipeline has finished running. Please check the log file to know the status of the run.</b><br>Download Output Files:<br><a href='../LOGFILE.now' download ><u>Run Log</u></a>  /  <a href='../"$outFolder"/run.log' download ><u>Detailed Run Log</u></a><br>" > .status

if [[ $ns == "on" ]] && [[ $gsd == "on" ]]
then
	HOST="localhost" auspice view --datasetDir $outFolder/Nextstrain_Files/$nsDir/auspice > /dev/null 2>run.log &
	pID=$(echo "$!")
	printf "<br><a href='../"$gsdMeta"' download><u>GISAID Metadata</u></a> <a href='../"$gsdFasta"' download><u>GISAID FASTA Sequences File</u></a><br>" >> .status
        printf "<br><a href='../"$ncFile"' download><u>Nextclade Report File</u></a><br>" >> .status
	printf "<br><a href='http://localhost:4000' target='_blank'> <u> Click here to view Nextstrain build for the run</u>" >> .status
elif [[ $ns == "on" ]]
then
        HOST="localhost" auspice view --datasetDir $nsDir/auspice > /dev/null 2>run.log &
	pID=$(echo "$!")
        printf "<br><a href='../"$ncFile"' download><u>Nextclade Report File</u></a><br>" >> .status
	printf "<br><a href='http://localhost:4000' target='_blank'> <u> Click here to view Nextstrain build for the run</u>" >> .status
else
	printf "<br><a href='../"$fastaFile"' download><u>Combined FASTA file</u></a> <a href='../"$summaryFile"' download><u>Sequencing Summary File</u></a><br>" >> .status
fi

