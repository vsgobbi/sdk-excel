Private Sub AfterTextBox_Change()
    Static reentry As Boolean
    If reentry Then Exit Sub
    
    reentry = True
    AfterTextBox.Text = Utils.formatDateInUserForm(AfterTextBox.Text)
    reentry = False
End Sub

Private Sub BeforeTextBox_Change()
    Static reentry As Boolean
    If reentry Then Exit Sub
    
    reentry = True
    BeforeTextBox.Text = Utils.formatDateInUserForm(BeforeTextBox.Text)
    reentry = False
End Sub

Private Sub UserForm_Initialize()
    Me.StatusBox.AddItem "Todos"
    Me.StatusBox.AddItem "Criados"
    Me.StatusBox.AddItem "Processando"
    Me.StatusBox.AddItem "Pagos"
    Me.StatusBox.AddItem "Falha"
    
    Me.StatusBox.Value = "Todos"
End Sub

Private Sub SearchButton_Click()
    On Error Resume Next

    Dim statusString As String: statusString = StatusBox.Value
    Dim cursor As String
    Dim payments As Collection
    Dim payment As Object
    Dim row As Integer
    Dim optionalParam As Dictionary: Set optionalParam = New Dictionary
    
    'Table layout
    Utils.applyStandardLayout ("G")
    Range("A10:G" & Rows.Count).ClearContents
    
    'Headers definition
    ActiveSheet.Cells(9, 1).Value = "Data de Criação"
    ActiveSheet.Cells(9, 2).Value = "Valor"
    ActiveSheet.Cells(9, 3).Value = "Status"
    ActiveSheet.Cells(9, 4).Value = "Data de Agendamento"
    ActiveSheet.Cells(9, 5).Value = "Linha Digitável"
    ActiveSheet.Cells(9, 6).Value = "Descrição"
    ActiveSheet.Cells(9, 7).Value = "Tags"
    
    With ActiveWindow
        .SplitColumn = 7
        .SplitRow = 9
    End With
    ActiveWindow.FreezePanes = True
    
    'Optional parameters
    Dim Status As String: Status = ChargePaymentGateway.getStatus(statusString)
    If Status <> "all" And Status <> "" Then
        optionalParam.Add "status", Status
    End If
    
    row = 10

    Do
        Set respJson = ChargePaymentGateway.getChargePayments(cursor, optionalParam)

        cursor = ""
        If respJson("cursor") <> "" Then
            cursor = respJson("cursor")
        End If

        Set payments = respJson("payments")

        For Each payment In payments

            Dim created As String: created = payment("created")
            ActiveSheet.Cells(row, 1).Value = Utils.ISODATEZ(created)

            ActiveSheet.Cells(row, 2).Value = payment("amount") / 100
            
            Dim paymentStatus As String: paymentStatus = payment("status")
            ActiveSheet.Cells(row, 3).Value = ChargePaymentGateway.getStatusInPt(paymentStatus)

            Dim scheduled As String: scheduled = payment("scheduled")
            ActiveSheet.Cells(row, 4).Value = Utils.ISODATEZ(scheduled)

            ActiveSheet.Cells(row, 5).Value = payment("line")
            ActiveSheet.Cells(row, 6).Value = payment("description")

            Dim tags As Collection: Set tags = payment("tags")
            ActiveSheet.Cells(row, 7).Value = CollectionToString(tags, ",")

            row = row + 1
        Next

    Loop While cursor <> ""
    
    Unload Me
     
End Sub