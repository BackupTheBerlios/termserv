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

  def __init__(self, optgroup, optname):

    self.type = 0
    self.name = ""
    self.vals = []
    self.userlevel = 1
    self.translate = 0

    # Set name from parm
    self.name = optname
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

class OptionsReader:

  opts = []

  def __init__(self):
    pass

  def getOptionGroups(self):

    opts = os.listdir("options/")
    return opts

  def getOptions(self, optgroup):

    self.opts = []
    for opt in os.listdir("options/" + optgroup + "/"):
      o = Option(optgroup, opt)
      self.opts.append(o)
    return self.opts

