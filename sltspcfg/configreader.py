from ConfigParser import *

class EConfigParser(ConfigParser):

  def optionxform(self, option):

    return str(option)

class ConfigReader:

  cp = 0
  path = ""

  def __init__(self, path):

    self.cp = EConfigParser()
    self.path = "lts.conf"
    self.cp.readfp(open(self.path))


  def getSections(self):

    return self.cp.sections()

  def getOptions(self, sect):

    return self.cp.options(sect)

  def getValue(self, sect, opt):

    return self.cp.get(sect, opt)

  def setValue(self, sect, opt, val):

    self.cp.set(sect, opt, val)

  def writeFile(self):

    self.cp.write(open(self.path, "w"))

  def removeOption(self, sect, opt):

   self.cp.remove_option(sect, opt)
