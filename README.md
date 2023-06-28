<p align="center">
  <img width="300"  src="https://raw.githubusercontent.com/banijolly/genepi-boxpox/main/logo.png">
</p>

## About
<b>Gen</b>etic <b>Epi</b>demiology in a <b>Box</b>for <b>Pox</b> viruses<br> 
genepi-boxpox is a tool developed for automating genome assembly and analysis of Lumpy Skin Disease Virus (LSDV) genomes to aid epidemiology and surveillance.<br>
<br>
The tool takes in as input:<br>
- A zip file (in .zip format) for paired-end short read sequencing data files (FASTQ files) of LSDV samples <br>
- The sample sheet used for demultiplexing the sequencing run from BCL to FASTQ files (in .csv format)
- A metadata file containing details of the samples (a tab separated text file). A sample metadata file ([Metadata_Example.tsv](https://github.com/banijolly/genepi-boxpox/blob/main/Metadata_Example.tsv)) is available in the repository. The header of the file (the first row) should remain the same. Second row of the sample metadata file contains examples of what values can be entered, this row can be deleted while adding new data. User can add their own data to the subsequent rows.

The tool will output a summary report for the analysis, including:<br>
- Detecting mutations<br>
- Coverage Statistics<br>
After installation, the tool can be opened as a web-page on the user's system

<b>The tool will work on a workstation/server with 64 bit Linux-based operating system, and has been validated on Ubuntu (16.04 LTS) Linux Distribution.</b>

## Quickstart

### Requirements
- git
- anaconda

### Installation
Clone the genepi-boxpox repository to your system using ```git clone https://github.com/banijolly/genepi-boxpox.git ```
To use conda, download and install the [latest version of Anaconda](https://www.anaconda.com/distribution/) to the <b>home directory of your system.</b>

Navigate into the cloned directory on your system:
``` cd genepi-boxpox ```

The tool can be installed by running the setup.sh installation script given in the repository. To install, run the following command:
``` ./setup.sh ```

### Running
To activate the conda environment, run:
``` conda activate genepi-box ```


After successful installation, the tool may be run by executing the command:
``` ./start.sh ```

This will initiate a local web-server on your system.
To open the tool interface, open the link  http://localhost:2000 on a web browser. The web-page is best suited to view on Google Chrome.

