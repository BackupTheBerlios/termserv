from wxPython.wx import *
from configreader import *
from editval import *
import string

ID_ABOUT = 101
ID_EXIT  = 102
ID_HOSTC = 103
ID_ADDOPT_BTN = 104
ID_MODOPT_BTN = 105
ID_DELOPT_BTN = 106
ID_SETTINGS = 107

class MyFrame(wxFrame):

    hostchooser = NULL
    settings = NULL
    addopt = NULL
    modopt = NULL
    delopt = NULL
    cr = ConfigReader("")

    def __init__(self, parent, ID, title):
        wxFrame.__init__(self, parent, ID, title, wxDefaultPosition, wxSize(500, 350))

        menu = wxMenu()
        menu.Append(ID_ABOUT, "&Discover new terminals", "More information about this program")
        menu.AppendSeparator()
        menu.Append(ID_EXIT, "E&xit", "Terminate the program")
        menuBar = wxMenuBar()
        menuBar.Append(menu, "&File");
        self.SetMenuBar(menuBar)

        EVT_MENU(self, ID_ABOUT, self.OnAbout)
        EVT_MENU(self, ID_EXIT,  self.TimeToQuit)

        # Sizer for the whole window
        wsizer = wxBoxSizer(wxVERTICAL)

        # Host selection
        hsel = wxBoxSizer(wxHORIZONTAL)
        htext = wxStaticText(self, -1, "Host", style=wxALIGN_LEFT)
        hsel.Add(htext, 0, wxALL | wxALIGN_BOTTOM, 2)
        self.hostchooser = wxComboBox(self, ID_HOSTC, "", style=wxCB_READONLY)
        hsel.Add(self.hostchooser, 0, wxALL, 2)
        EVT_COMBOBOX(self,ID_HOSTC, self.onChangeHost)

        wsizer.Add(hsel, 0, wxALL, 5)

        # The list box
        self.settings = wxListBox(self, ID_SETTINGS)
        wsizer.Add(self.settings, 1, wxEXPAND | wxALL, 5)
        EVT_LISTBOX(self, ID_SETTINGS, self.onSettingsSelect)

        # The buttons at the bottom
        btnsizer = wxBoxSizer(wxHORIZONTAL)

        self.addopt = wxButton(self, ID_ADDOPT_BTN, "Add")
        self.addopt.Enable(FALSE)
        btnsizer.Add(self.addopt, 0, wxALIGN_BOTTOM, 3)
        self.modopt = wxButton(self, ID_MODOPT_BTN, "Modify")
        self.modopt.Enable(FALSE)
        btnsizer.Add(self.modopt, 0, wxALIGN_BOTTOM, 3)
        EVT_BUTTON(self, ID_MODOPT_BTN, self.modifyOption)
        self.delopt = wxButton(self, ID_DELOPT_BTN, "Delete")
        self.delopt.Enable(FALSE)
        btnsizer.Add(self.delopt, 0, wxALIGN_BOTTOM, 3)
        EVT_BUTTON(self, ID_DELOPT_BTN, self.deleteOption)

        wsizer.Add(btnsizer, 0, wxALL, 5)

        # Fill the host chooser

        self.fillHostChooser()
        self.hostchooser.SetSelection(0)
        self.onChangeHost(NULL)

        # Tell the frame to use the sizer system
        self.SetAutoLayout( TRUE )
        self.SetSizer( wsizer )

    # Host Chooser & Option List Functions

    def onChangeHost(self, event):
        self.settings.Clear()
        i = self.hostchooser.GetValue()
        for j in self.cr.getOptions(i):
          self.settings.Append(j + ": " + self.cr.getValue(i,j))
        self.addopt.Enable(TRUE)
        self.modopt.Enable(FALSE)
        self.delopt.Enable(FALSE)

    def fillHostChooser(self):
        self.hostchooser.Clear()
        for i in self.cr.getSections():
            self.hostchooser.Append(i)
        self.addopt.Enable(TRUE)
        self.modopt.Enable(FALSE)
        self.delopt.Enable(FALSE)

    def onSettingsSelect(self, event):
        self.addopt.Enable(TRUE)
        self.modopt.Enable(TRUE)
        self.delopt.Enable(TRUE)
        
    # Option button functions

    def deleteOption(self, event):

        optname = string.split(self.settings.GetStringSelection(), ":")[0]
        sectname = self.hostchooser.GetValue()
        self.cr.removeOption(sectname, optname)
        self.onChangeHost(NULL)
        self.addopt.Enable(TRUE)
        self.modopt.Enable(FALSE)
        self.delopt.Enable(FALSE)

    def modifyOption(self, event):
        sectname = self.hostchooser.GetValue()
        optname = string.strip(string.split(self.settings.GetStringSelection(), ":")[0])
        val = string.strip(string.split(self.settings.GetStringSelection(), ":")[1])
        setsel = self.settings.GetSelection()

        dlg = EditDlg(self, -1, "Edit Value", sectname, optname, val, self.cr)
        dlg.ShowModal()
        dlg.Destroy()

        self.onChangeHost(None)

        self.settings.SetSelection(setsel)
        self.addopt.Enable(TRUE)
        self.modopt.Enable(TRUE)
        self.delopt.Enable(TRUE)


    # Other functions

    def OnAbout(self, event):
        dlg = wxMessageDialog(self, "Simple LTSP Configuration Program\n(c) Christian Selig 2002", "About sltspcfg", wxOK | wxICON_INFORMATION)
        dlg.ShowModal()
        dlg.Destroy()

    def TimeToQuit(self, event):
        self.cr.writeFile()
        self.Close(true)



class MyApp(wxApp):
    def OnInit(self):
        frame = MyFrame(NULL, -1, "Hello from wxPython")
        frame.Show(true)
        self.SetTopWindow(frame)
        return true

app = MyApp(0)
app.MainLoop()



