from wxPython.wx import *

ID_OK = 201
ID_CANCEL = 202

class EditDlg(wxDialog):

    sectname = ""
    optname = ""
    curval = ""
    cr = None
    val = None

    def __init__(self, parent, ID, title, sectname, optname, curval, cr=None):

        wxDialog.__init__(self, parent, ID, title, wxDefaultPosition, wxSize(200, 100))
        self.sectname = sectname
        self.optname = optname 
        self.curval = curval
        self.cr = cr

        wsizer = wxBoxSizer(wxVERTICAL)

        # Option name
        oname = wxBoxSizer(wxHORIZONTAL)
        oname_l = wxStaticText(self, -1, "Option ", style=wxALIGN_LEFT)
        oname.Add(oname_l, 0, wxALL | wxALIGN_BOTTOM, 2)
        oname_l2 = wxStaticText(self, -1, optname)
        oname.Add(oname_l2, 0, wxALL, 2)

        wsizer.Add(oname, 0, wxALL, 5)

        # Edit field
        ed = wxBoxSizer(wxHORIZONTAL)
        ed_l = wxStaticText(self, -1, "Value ", style=wxALIGN_LEFT)
        ed.Add(ed_l, 1, wxEXPAND | wxALL, 5)
        self.val = wxTextCtrl(self, -1, curval, style=wxALIGN_LEFT)
        ed.Add(self.val, 1, wxEXPAND | wxALL, 5)
        wsizer.Add(ed, 0, wxALL, 5)

        # The buttons at the bottom
        btnsizer = wxBoxSizer(wxHORIZONTAL)

        okbtn = wxButton(self, ID_OK, "OK")
        btnsizer.Add(okbtn, 0, wxALIGN_BOTTOM, 3)
        EVT_BUTTON(self, ID_OK, self.okDialog)

        cancelbtn = wxButton(self, ID_CANCEL, "Cancel")
        btnsizer.Add(cancelbtn, 0, wxALIGN_BOTTOM, 3)
        EVT_BUTTON(self, ID_CANCEL, self.cancelDialog)

        wsizer.Add(btnsizer, 0, wxALL, 5)

        # Tell the frame to use the sizer system
        self.SetAutoLayout( TRUE )
        self.SetSizer( wsizer )

    def okDialog(self, event):

        self.cr.setValue(self.sectname, self.optname, self.val.GetValue())
        self.SetReturnCode(1)
        self.Close(true)

    def cancelDialog(self, event):
        self.SetReturnCode(0)
        self.Close(true)

