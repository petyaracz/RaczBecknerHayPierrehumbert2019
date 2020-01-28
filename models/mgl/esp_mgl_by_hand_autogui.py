################################################################
# MGL batch runner script
# pracz
################################################################

# The MGL can run batch files. However, if it does, it does not use feature files, even if these are available under the same name as the input file.

# To run the MGL using features properly, you need to run these by hand. You also need to quit and reopen the MGL every time, otherwise it fits without using features the second and subsequent times.

# The only way to do it is by hand.

# The script below moves the cursor and types.
# It launches the MGL, sets parameters, fits one input file, quits the MGL.
# It does this i times.

# Good to know:
#   - you can break an autogui script by moving the mouse in one corner of the screen
#   - pyautogui.click doesn't really work on Mac Os mojave, the below script uses a workaround
#   - even so, you need to add the interface that launches the script (e.g. pycharm, iterm2, terminal) as well as the appropriate python launcher to apps that can control the computer in Security & Privacy / Accessibility
#   - it's not a good idea to allow anything to control the computer like that in the long run

import pyautogui
import time

# takes two coordinates on the computer screen and a duration, returns a left mouse click on the coordinates after duration.
def clickThing(x, y, duration = 2):

    pyautogui.moveTo(x, y, duration = duration)
    pyautogui.dragTo(x, y, button='left')
    #pyautogui.click(x, y, button='left')

# runs the MGL
# assumes:
#   - iMac (Retina 4K, 21.5-inch, 2019)
#   - resolution: width=1680, height=945 (scaled one to Larger)
#   - MinGenLearner.jar icon on desktop, bottom left corner, visible
#   - MinGenLearner opens upper right corner

def runGuy(input_file_name):

    # click on MinGenLearner.jar and then double click
    clickThing(1632, 858)
    pyautogui.doubleClick(1632, 858)

    # move SLOWLY to tick Show All Options box in MGL gui (so it has time to boot up)
    clickThing(44, 120, duration = 10)

    # click into Lower confidence limit, move it to .55, enter
    clickThing(450, 244)
    for i in range(1, 5):
        pyautogui.press('up')

    pyautogui.press('enter')

    # click into Upper confidence limit, move it to .95, enter
    clickThing(450, 268)
    for i in range(1, 5):
        pyautogui.press('down')

    pyautogui.press('enter')

    # Click open input file
    clickThing(405, 76)

    # search
    pyautogui.keyDown('command')
    pyautogui.write('f')
    pyautogui.keyUp('command')

    # look for input file name
    pyautogui.write(input_file_name)
    pyautogui.press('enter')

    # restrict search to files created in the last three days.
    # I use this because I have several copies of the same files and want to modify specific ones.
    clickThing(1223, 200)

    clickThing(640, 233)

    clickThing(640, 278)

    pyautogui.write('3')
    pyautogui.press('enter')

    clickThing(680, 278)

    pyautogui.press('enter')

    # run MGL. it takes about 45-50 seconds on my machine
    clickThing(309, 106)
    # wait a bit longer, then click into MGL and quit
    time.sleep(60)

    clickThing(251, 99)

    pyautogui.keyDown('command')
    pyautogui.write('q')
    pyautogui.keyUp('command')

    # if you restart the MGL too fast it throws an error, so we wait a bit
    time.sleep(3)

# this loop goes through the participants
for i in range(0, 223):
    input_file_name = f'input_part{i}.in'
    runGuy(input_file_name)
