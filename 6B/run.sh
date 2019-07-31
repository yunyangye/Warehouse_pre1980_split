#!/bin/bash

#SBATCH --nodes=2
#SBATCH --ntasks=24
#SBATCH --time=06-23
#SBATCH --partition=shas
#SBATCH --qos=long
#SBATCH --output=sample-%j.out

module load python
module load R
python main.py
