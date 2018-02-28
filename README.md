# Introduction #
A ruby application for generating KSP code to go along with Sampler Instruments for the Native Instruments Kontakt 
sampler software.

KSP scripts often have lots of repeated code, but as a developer this is just a hassle to work with. There some 
excellent tools available to assist you in writing less code by simulating more advanced datatypes, control structures, 
even objects and functions with arguments.
I've used some of these myself with great results, and I am in no way discouraging use of these tools. In my own case, 
however, I wanted something which I could just throw a configuration file after, and then it would spit out the KSP code 
I needed. Plus I wanted to experiment more with Ruby - as part of a learning process.  

It takes a yaml file with specifications on the elements (knobs, buttons, labels and variables) you want, and allows you 
to configure each of these elements in detail. The idea is that functions and callbacks will be added automatically.

The application is used specifically to generate the code behind the [Beaotic][beaotic] instruments, while the ksp gem 
is supposed to be a generic tool for any KSP project.

I've only done a few Rails projects before this, so I'm not particularly experienced with Ruby. Comments and suggestions 
for improvements are warmly welcomed!

# Status #
Definitely work in progress - not mature at all! Use at your own risk :)

I'm changing a lot of stuff between every push while I'm figuring out how to structure the whole thing.

I do not care so much about the output layout of the generated KSP code, but I may add some kind of formatting engine 
later on, if I can find one.

# The Beaotic application #
The Beaotic instruments are based on the same feature set, although with some notable variations. They all have the same 
set of key groups, which are usually called by the same names, and usually have the same members.

The instruments always provide two views for editing and mixing respectively. The edit panels have a set of knobs, 
varying in both functionality and underlying implementation of same functionality. They also have buttons - these vary 
much less.

In the mixer panel, the controls are always the same, they are called by predictable names, and they work in the same 
way - only on different targets.

A "button" is used within each instrument group to switch between mixer and edit panel.

Most edit knobs deal with setting a single parameter for a number of Kontakt-groups. But a few do different stuff, for 
example:
* OSC 2 level
  * Set a volume coefficient on certain groups
* OSC 1/2 crossfade
  * Set volume coefficients on two certain sets of groups
* Accent
  * Set a volume coefficient on certain groups
* Color
  * Allow/disallow specific sets of samples, for example to simulate a hardware filter using 32 different "color" steps.

# Usage #
Something like this...

`ruby beaotic.rb xt808`

Such a command should look for a file name xt808.yml, process it and save the generated code in xt808.txt

[beaotic]: https://beaotic.com