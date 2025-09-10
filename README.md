# Author List Generator

This repository provides a Bash script that converts two simple text files (one describing authors and their affiliation keys, and another describing affiliation texts with keys) into a formatted scientific paper–style author list with numbered affiliations.

---

## Files

- `make_author_list.sh` – the script
- `README.md` – this documentation
- Example input files:
  - `authors.txt`
  - `affiliations.txt`

---

## Usage

Make the script executable:

```bash
chmod +x make_author_list.sh
```

---

## Input File Formats

#### 1. Authors file (authors.txt)

Each line = one author.

Fields are separated by semicolons (;).

First field = author's full name.

Following fields = affiliation keys (must match keys from affiliations.txt).

An author can have one or multiple keys (listed once per author).

Example (authors.txt):

```txt
Kira E. Detrois; FIMM
Tuomo Hartonen; FIMM
Maris Teder-Laving; TARTU
Bradley Jermy; FIMM
Kristi Läll; TARTU
Zhiyu Yang; FIMM
Reedik Mägi; TARTU
Samuli Ripatti; FIMM; BROAD; MGH; HELSINKI
Andrea Ganna; FIMM; BROAD; MGH
```
#### 2. Affiliations file (affiliations.txt)

Each line = one affiliation.

Two fields, separated by a semicolon (;):

Full affiliation text

Affiliation key (matches keys used in authors.txt)

Example (affiliations.txt):

```txt
Institute for Molecular Medicine Finland, FIMM, HiLIFE, University of Helsinki, Helsinki, Finland.; FIMM
Estonian Genome Centre, Institute of Genomics, University of Tartu, Tartu, Estonia; TARTU
Broad Institute of MIT and Harvard, Cambridge, MA, USA.; BROAD
Analytic and Translational Genetics Unit, Massachusetts General Hospital, Boston, MA, USA.; MGH
Department of Public Health, University of Helsinki, Helsinki, Finland.; HELSINKI
```

### Example Run

Using the bundled example files:

```bash
./make_author_list.sh authors.txt affiliations.txt
```

The script will output:

```
Kira E. Detrois1, Tuomo Hartonen1, Maris Teder-Laving2, Bradley Jermy1, Kristi Läll2, Zhiyu Yang1, Reedik Mägi2, Samuli Ripatti1,3,4,5 & Andrea Ganna1,3,4

1) Institute for Molecular Medicine Finland, FIMM, HiLIFE, University of Helsinki, Helsinki, Finland.
2) Estonian Genome Centre, Institute of Genomics, University of Tartu, Tartu, Estonia
3) Broad Institute of MIT and Harvard, Cambridge, MA, USA.
4) Analytic and Translational Genetics Unit, Massachusetts General Hospital, Boston, MA, USA.
5) Department of Public Health, University of Helsinki, Helsinki, Finland.
```
