Public Function getStatus(Status As String)
    Select Case Status
        Case "Todos": getStatus = "all"
        Case "Pagos":  getStatus = "paid"
        Case "Pendentes de Registro":  getStatus = "created"
        Case "Registrados":  getStatus = "registered"
        Case "Vencidos":  getStatus = "overdue"
        Case "Cancelados":  getStatus = "canceled"
    End Select
End Function

Public Function getStatusInPt(Status As String)
    Select Case Status
        Case "paid":  getStatusInPt = "pago"
        Case "created":  getStatusInPt = "pendente de registro"
        Case "registered":  getStatusInPt = "registrado"
        Case "overdue":  getStatusInPt = "vencido"
        Case "canceled":  getStatusInPt = "cancelado"
        Case "failed":  getStatusInPt = "falha"
        Case "unknown":  getStatusInPt = "desconhecido"
    End Select
End Function

Public Function getStatusFromId(id As String)
    Select Case id
        Case "00":  getStatusFromId = "register"
        Case "02":  getStatusFromId = "registered"
        Case "03":  getStatusFromId = "failed"
        Case "06":  getStatusFromId = "paid"
        Case "09":  getStatusFromId = "canceled"
        Case Else:  getStatusFromId = "unknown"
    End Select
End Function

Public Function getOccurrenceId(statusCode As String)
    Select Case statusCode
        Case "pendente de registro"
            getOccurrenceId = "00"
        Case "registrado"
            getOccurrenceId = "02"
        Case "vencido"
            getOccurrenceId = "02"
        Case "falha"
            getOccurrenceId = "03"
        Case "pago"
            getOccurrenceId = "06"
        Case "cancelado"
            getOccurrenceId = "09"
        Case Else
            getOccurrenceId = "99"
    End Select
End Function

Public Function getCharges(cursor As String, optionalParam As Dictionary)
    Dim query As String
    Dim resp As response
    
    query = ""
    If cursor <> "" Then
        query = "?cursor=" + cursor
    End If
    
    If optionalParam.Count > 0 Then
        For Each key In optionalParam
            If query = "" Then
                query = "?" + key + "=" + CStr(optionalParam(key))
            Else
                query = query + "&" + key + "=" + CStr(optionalParam(key))
            End If
        Next
    End If
    
    Set resp = StarkBankApi.getRequest("/v1/charge", query, New Dictionary)
    
    If resp.Status = 200 Then
        Set getCharges = resp.json()
    Else
        MsgBox resp.error()("message"), , "Erro"
    End If

End Function

Public Function getCustomers(cursor As String, optionalParam As Dictionary)
    Dim query As String
    Dim resp As response
    
    query = ""
    If cursor <> "" Then
        query = "?cursor=" + cursor
    End If
    
    If optionalParam.Count > 0 Then
        For Each key In optionalParam
            If query = "" Then
                query = "?" + key + "=" + CStr(optionalParam(key))
            Else
                query = query + "&" + key + "=" + CStr(optionalParam(key))
            End If
        Next
    End If
    
    Set resp = StarkBankApi.getRequest("/v1/charge/customer", query, New Dictionary)
    
    If resp.Status = 200 Then
        Set getCustomers = resp.json()
    Else
        MsgBox resp.error()("message"), , "Erro"
    End If

End Function

Public Function getOrders() As Collection
    Dim orders As New Collection
    
    For Each obj In SheetParser.dict
        Dim amount As Long
        Dim customerId As String
        Dim dueDate As String
        Dim fine As Single: fine = 2
        Dim interest As Single: interest = 1
        Dim overdueLimit As Long: overdueLimit = 59
        Dim description1 As Dictionary: Set description1 = New Dictionary
        Dim description2 As Dictionary: Set description2 = New Dictionary
        Dim description3 As Dictionary: Set description3 = New Dictionary
        Dim order As Dictionary
        
        If obj("Valor") = "" Then
            MsgBox "Por favor, não deixe linhas em branco entre as ordens de cobrança", , "Erro"
        End If
        amount = Utils.IntegerFrom((obj("Valor")))
        customerId = Trim(obj("Id do Cliente"))
        dueDate = Utils.DateToSendingFormat((obj("Data de Vencimento")))
        
        If obj("Multa") <> "" Then
            fine = Utils.SingleFrom((obj("Multa")))
        End If
        
        If obj("Juros ao Mês") <> "" Then
            interest = Utils.SingleFrom((obj("Juros ao Mês")))
        End If
        
        If obj("Dias para Baixa Automática") <> "" Then
            overdueLimit = Utils.IntegerFrom((obj("Dias para Baixa Automática")))
        End If
        
        If obj("Descrição 1") <> "" Then
            description1.Add "text", obj("Descrição 1")
        End If
        If obj("Valor 1") <> "" Then
            description1.Add "amount", Utils.IntegerFrom((obj("Valor 1")))
        End If
        
        If obj("Descrição 2") <> "" Then
            description2.Add "text", obj("Descrição 2")
        End If
        If obj("Valor 2") <> "" Then
            description2.Add "amount", Utils.IntegerFrom((obj("Valor 2")))
        End If
        
        If obj("Descrição 3") <> "" Then
            description3.Add "text", obj("Descrição 3")
        End If
        If obj("Valor 3") <> "" Then
            description3.Add "amount", Utils.IntegerFrom((obj("Valor 3")))
        End If
        
        Set order = ChargeGateway.order(amount, customerId, dueDate, fine, interest, overdueLimit, description1, description2, description3)
    
        orders.Add order
        
    Next
    Set getOrders = orders
End Function

Public Function order(amount As Long, customerId As String, dueDate As String, fine As Single, interest As Single, overdueLimit As Long, description1 As Dictionary, description2 As Dictionary, description3 As Dictionary) As Dictionary
    Dim dict As New Dictionary
    Dim descriptions As New Collection
    
    If description1.Count > 0 Then
        descriptions.Add description1
    End If
    If description2.Count > 0 Then
        descriptions.Add description2
    End If
    If description3.Count > 0 Then
        descriptions.Add description3
    End If
    
    dict.Add "amount", amount
    dict.Add "customerId", customerId
    dict.Add "dueDate", dueDate
    dict.Add "fine", fine
    dict.Add "interest", interest
    dict.Add "overdueLimit", overdueLimit
    dict.Add "descriptions", descriptions
    
    Set order = dict
    
End Function

Public Function createCharges(charges As Collection)
    Dim resp As response
    Dim payload As String
    Dim dict As New Dictionary
    
    dict.Add "charges", charges
    
    payload = JsonConverter.ConvertToJson(dict)
    
    Set resp = StarkBankApi.postRequest("/v1/charge", payload, New Dictionary)
    
    If resp.Status = 200 Then
        createCharges = resp.json()("message")
        MsgBox resp.json()("message"), , "Sucesso"
        
    ElseIf resp.error().Exists("errors") Then
        Dim errors As Collection: Set errors = resp.error()("errors")
        Dim error As Dictionary
        Dim errorList As String
        Dim errorDescription As String
        
        For Each error In errors
            errorDescription = Utils.correctErrorLine(error("message"), 9)
            errorList = errorList & errorDescription & Chr(10)
        Next
        
        Dim messageBox As String
        messageBox = resp.error()("message") & Chr(10) & Chr(10) & errorList
        MsgBox messageBox, , "Erro"
        
    Else
        MsgBox resp.error()("message"), , "Erro"
        
    End If
    
End Function

Public Function getEventLog(chargeId As String, logevent As String, optionalParam As Dictionary)
    Dim query As String
    Dim resp As response
    Dim elem As Variant
    
    query = ""
    If chargeId <> "" Then
        query = "?events=" + logevent + "&chargeIds=" + chargeId
    End If
    If optionalParam.Count > 0 Then
        For Each key In optionalParam
            If query = "" Then
                query = "?" + key + "=" + CStr(optionalParam(key))
            Else
                query = query + "&" + key + "=" + CStr(optionalParam(key))
            End If
        Next
    End If
    Set resp = StarkBankApi.getRequest("/v1/charge/log", query, New Dictionary)
    If resp.Status = 200 Then
        Set logArray = resp.json()
    Else
        MsgBox resp.error()("message"), , "Erro"
    End If
    
    Set getEventLog = logArray

End Function

