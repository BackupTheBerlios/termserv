import os, sys
import string

OPTION_TEXT = 1
OPTION_IP = 2
OPTION_SELECT = 3

class Option:

  name = ""
  vals = []
  type = 0
  userlevel = 1
  translate = 0
  group = ""

  def __init__(self, optgroup, optname):

    self.type = 0
    self.name = optname
    self.vals = []
    self.userlevel = 1
    self.translate = 0
    self.group = optgroup

    # Set name from parm
    optpath = "options/" + optgroup + "/" + optname + "/"

    # Find out type of option
    if (os.access(optpath + "ip", os.F_OK)):
      self.type = OPTION_IP
    elif (os.access(optpath + "select", os.F_OK)):
      self.type = OPTION_SELECT
    elif (os.access(optpath + "text", os.F_OK)):
      self.type = OPTION_TEXT

    # needs translation?
    if (os.access(optpath + "translate", os.F_OK)):
      self.translate = 1
    else:
      self.translate = 0

    # which userlevel?
    if (not os.access(optpath + "userlevel", os.F_OK)):
      self.userlevel = 1
    else:
      fh = open(optpath + "userlevel", "r")
      self.userlevel = string.strip(fh.read())
      fh.close()

    # If select, then get list of values from file

    if (self.type == OPTION_SELECT):
      fh = open(optpath + "options", "r")
      for opt in string.split(fh.read(), "\n"):
        if (opt != ""):
          self.vals.append(string.strip(opt))
      fh.close()
    else:
      self.vals = []


  def getName(self):
    return self.name

  def getType(self):
    return self.type

  def getPossibleValues(self):
    return self.vals

  def getTranslate(self):
    return self.translate

  def getUserLevel(self):
    return self.userlevel

  def getGroup(self):
    return self.group


class OptionGroup:

  optionnames = []
  options = []
  groupname = ""

  def __init__(self, grpname):
    self.optionnames = os.listdir("options/" + grpname)
    self.groupname = grpname
    for i in self.optionnames:
      self.options.append(Option(grpname, i))

  def getOptions(self):
    return self.options

  def getOptionNames(self):
    return self.optionnames

  def getName(self):
    return self.groupname

  def hasOption(self, nm):
    if nm in self.optionnames:
      return self.getOption(nm)
    return None

  def getOption(self, nm):
    for i in self.options:
      if i.getName() == nm:
        return i
    return None

class OptionsReader:

  groupnames = []
  groups = []

  def __init__(self):
    self.groupnames = os.listdir("options/")
    for i in self.groupnames:
      self.groups.append(OptionGroup(i))

  def getGroupNames(self):
    return self.groupnames

  def getGroups(self):
    return self.groups

  def getGroup(self, nm):
    for i in self.groups:
      if i.getName() == nm:
        return i
    return None

  def getOption(self, nm):
    for i in self.groups:
      for j in i.getOptions():
        if j.getName() == nm:
          return j
    return None