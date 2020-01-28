# MGL workflow

## Basics

The MGL is a java package file. It comes with a button interface. 

MGL fits have a number of parameters. Two are relevant here. The confidence levels are always the same in the fits reported here; a lower confidence of 55 and an upper confidence of 95. We came to these values by experimentation and cross-referencing previous literature, this is not included here. You can also tell the MGL to use feature-based distance or edit distance.

We fit the MGL using both edit-distance and feature distance.

## Baseline MGL

Replicating the baseline results is straightforward: I added the input file we used (CELEX3.in) which already has the test forms included. I added the rule set extracted by the MGL with and without features for reference.

## Individual / ESP MGL

I'm trying to reconstruct this from my own bug logs so it might not be 100% accurate on what doesn't work. I'm relatively confident on what does work. Bugs have been reported to the package authors.

You can fit the MGL on batches using a batch file and a CLI. It will not, however, use feature files -- it will default to edit distance. It won't tell you this. This, I think, doesn't change even if you include feature files with identical names to the input file (the old subtitle trick). 

The MGL with no features was fit on the esp data this way, for each participant in the reported dataset.

If you want features, you have to fit sets individually. You have to also have a separate feature file for each set. You have to quit and reopen the MGL each time after fit.

I automated this using pyautogui in python, see esp_mgl_by_hand_autogui. This script is absolutely and utterly specific to my screen dimensions, but it can be adapted to replicate the process.