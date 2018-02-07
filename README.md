# Status #

Definitely work in progress - not mature at all!

I hope for this project to mature over the next couple of months, at least so that it can support the development of the Beaotic sample libraries that I'm working on. By that time it would be cool if anybody else would like to contribute.

# Background #

Our instruments are bult around the same template, with a few variations.

They all have the same set of key groups, which are usually called by the same names, and usually have the same members.

Each key group always have two panels: Main and Mixer.

The Main panel always have a set of knobs, and these vary quite a bit.
Aside from the knobs, they have a set of buttons, which vary much less.

In the mixer panel, the controls are always the same, they are called by the same names, and they work in the same way.

A button is used within each instrument group to switch between Mixer and Main panel. We may consider to move this functionality out to a general "working mode" level instead of having it on each key group.

Most knobs deal with setting a single parameter for a number of Kontakt-groups. But a few do different stuff:
- OSC 2 level
-- Set a volume coefficient on certain groups
- OSC 1/2 crossfade
-- Set volume coefficients on two certain sets of groups
- Accent
-- Set a volume coefficient on certain groups

So, since KSP is a very limited programming language, I've decided to write a code generator for KSP - in Ruby.

It is not - currently - a generic tool for this purpose, but yes, it would be nice to turn it into one over time, just for fun :)

- Keep dependencies minimal. Preferably no gems should be required
- Keep code rganized. I expect to just write a bunch of functions first, and then possibly wrap them into classes along the way.

I do not care so much about the output layout of the generated KSP code. For example, I do not care about code repetitions, since the whole point of using another more flexible programming language is to avoid the repetitions **here**.

# Tasks #

So what do I expect in terms of tasks..?

One thing I know, is that I'd like to have a program that is generic enough to produce a valid KSP script based on a YAML file as an input parameter. Something like:

`ruby ksp.rb xt808.yml`

Let's start backwards, looking at the requirements of the generated KSP code:

We need callback handlers for ui controls and notes. 

ui control callback handlers listens for events on a ui control, and adjusts what ever parameters are required.

But how do I determine what actions to take on which targets?

Let's take an example... The pitch-knob is turned on the HH1 main panel.

The code for this could end up something like the following:

```
on ui_control(knob_hh1_main_pitch)
  set_engine_par($ENGINE_PAR_TUNE, hh1_pitch, grp_idx_hh1_0, -1, -1)
  set_engine_par($ENGINE_PAR_TUNE, hh1_pitch, grp_idx_hh1_1, -1, -1)
  set_engine_par($ENGINE_PAR_TUNE, hh1_pitch, grp_idx_hh1_2, -1, -1)
  ...
end on
```

But... Since several knobs or sliders may affect the same parameter, we should let a function handle the actual setting of the value. The following example shows how we want the callbacks of the 4 knobs that ultimately control the pitch of any key in the hh1 key group to look, including functions.

```
function set_hh1_0_pitch
  $hh1_0_pitch_val := $knob_hh1_0_pitch + $knob_hh1_main_pitch
  set_engine_par($ENGINE_PAR_TUNE, hh1_0_pitch_val, $grp_idx_hh1_0, -1, -1)
end function

function set_hh1_1_pitch
  $hh1_1_pitch_val := $knob_hh1_1_pitch + $knob_hh1_main_pitch
  set_engine_par($ENGINE_PAR_TUNE, $hh1_0_pitch_val, $grp_idx_hh1_0, -1, -1)
end function

function set_hh1_2_pitch
  $hh1_2_pitch_val := $knob_hh1_2_pitch + $knob_hh1_main_pitch
  set_engine_par($ENGINE_PAR_TUNE, $hh1_0_pitch_val, $grp_idx_hh1_0, -1, -1)
end function

function set_hh1_main_pitch
  set_hh1_0_pitch
  set_hh1_1_pitch
  set_hh1_2_pitch
end function

on ui_control($knob_hh1_main_pitch)
  set_hh1_main_pitch
end on

on ui_control($knob_hh1_0_pitch)
  set_hh1_0_pitch
end on

on ui_control($knob_hh1_1_pitch)
  set_hh1_0_pitch
end on

on ui_control($knob_hh1_2_pitch)
  set_hh1_0_pitch
end on
```


Configuration snippet required to support the above:

```
# define some default blocks, such as pitch:
default_pitch: &default_pitch
  name: pitch
  default_value: 500000
  max_value: 700000
  min_value: 300000  
  label: Pitch

key_groups:
  - short_name: hh1
    long_name: "XT-808 High-hats 1"
    panels:
      main:
        knobs:
          - pitch: *default_pitch
            notes: [0,1,2]            
          - name: cl_hh_decay
            notes: [0, 1]
          - name: o_hh_hold
            notes: [2]
          - name: o hh decay
            notes: [2]
        buttons:
          - name: osc_drift


  - name: toms
    knobs:
      tom_1_pitch: *default_pitch
        label: "Tom 1 pitch"
      tom_2_pitch: *default_pitch
        label: "Tom 2 pitch"
      ...  
```



So, in other words, I want all the pitch knobs to have the same range and default value, but different targets and correspondingly different labels. The yaml extract above show how to do this, I think...


For this to work, we need to know which groups to change the pitch for, so that we may loop over them in the ruby code. Since we follow a strict system when it comes to the number of groups, and their order (with/without accent, RR-vairants, color-variants etc), so I feel confident about that part.



So, to imagine how this would look in the yaml configuration, I would like to be able to specifiy a function per knob.

    







