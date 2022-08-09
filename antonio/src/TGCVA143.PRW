#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

#xtranslate AMtoCmp( <v1> )       => Right(<v1>, 2) + "/" + Left(<v1>, 4)
#xtranslate CmptoAM( <v1> )       => Right(<v1>, 4) + Left(<v1>, 2)


Static __aPH61   := {}
Static __aPH62   := {}
Static __aPH63   := {}
Static __aProdCorp := {} 

User Function GCVA143()   
    CN9->(DbGoto((cAliasTrb)->CN9_RECNO))
    U_GCVA143V()  
Return 

User Function GCVA143V()
    Local bSavKeyF12

    If CN9->CN9_SITUAC != "05"
        MsgStop("Posicionar na revisão vigente!!!")
        Return 
    EndIf 

    FwPutSX5("", "GV", "000032" , "Geração Pedido de Venda Lote"          , "Geração Pedido de Venda Lote"          , "Geração Pedido de Venda Lote"  )
    FwPutSX5("", "GV", "000033" , "Exclusão Pedido de Venda Lote"         , "Exclusão Pedido de Venda Lote"         , "Exclusão Pedido de Venda Lote" )

    __aPH61    := {}
    __aPH62    := {}
    __aPH63    := {}
    
    
    U_TIProcessa({|| LoadPH5()},"Carregando...",,) 

    bSavKeyF12:= SetKey(VK_F12,{|| U_TILastLog()  })

    FWExecView("Geração de Pedido",'TGCVA143', MODEL_OPERATION_UPDATE,, {|| .T.}) 
    
    SetKey(VK_F12, bSavKeyF12)

Return


Static Function LoadPH5()
    Local aArea     := GetArea()
    Local aAreaCN9  := CN9->(GetArea())
    Local aAreaCNB  := CNB->(GetArea())
    Local aAreaPH5  := PH5->(GetArea())
    Local aAreaSM0  := SM0->(GetArea())
    Local cSql      := ""
    Local clAlias   := ""
    Local cDesc     := ""
    Local dDtSitu   := ctod('')

    
    Local nRecno    := 0
    Local aPH5Aux   := {}
    Local cKeyPH5   := ""
    Local cSeqPh5   := ""
    Local cAgrLRec  := GETMV("TI_AGRLREC") 
    Local cParcNum  := GetNewPar("TI_PARCNUM", "123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0")  

    U_TIProcMsg("Carregando Pedido ")
 
    U_TIProcLog("Executando Query")
    cSql    := MtaQry()
    clAlias := GetNextAlias()
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cSql),clAlias,.F.,.T.)
 
    MtaProdCorp()  // monta lista com todos os produtos corporativos

    U_TIProcLog("Lendo cronograma")
    While (clAlias)->(!Eof())
        nRecno  := (clAlias)->RECNO
        cKeyPH5 := (clAlias)->(PH5_CONTRA+PH5_REVISA+PH5_NUMERO+PH5_COMPET+PH5_CONDIC+PH5_CLIENT+PH5_LOJA+PH5_CONDPG+PH5_NOTASE+PH5_MOEDA+PH5_MASCCC+PH5_GU)
        cSeqPh5 := (clAlias)->PH5_SEQ
        cDesc   := (clAlias)->CNB_DESCRI
        dDtSitu := STOD((clAlias)->CNB_DTSITU)

        PH5->(DbGoto(nRecno))
        ItensPH5(aPH5Aux, cDesc, dDtSitu)        

        (clAlias)->(dbSkip())
        
        If (clAlias)->(Eof()) .or. ! cKeyPH5 + cSeqPh5 == (clAlias)->(PH5_CONTRA+PH5_REVISA+PH5_NUMERO+PH5_COMPET+PH5_CONDIC+PH5_CLIENT+PH5_LOJA+PH5_CONDPG+PH5_NOTASE+PH5_MOEDA+PH5_MASCCC+PH5_GU+PH5_SEQ)
            CabecPH6(aPH5Aux, cKeyPH5, cSeqPh5, cAgrLRec, cParcNum, dDtSitu)
            aPH5Aux := {}
        EndIf  
  
    EndDo  

    RestArea(aAreaSM0)
    RestArea(aAreaPH5)
    RestArea(aAreaCNB)
    RestArea(aAreaCN9)
    RestArea(aArea)
Return 

Static Function ItensPH5(aPH5Aux, cDesc, dDtSitu)
    Local aAux       := {} 
    Local cDesStatRM := ""
    Local cLegenda   := ""
    Local cCorp      := "NAO"
    
    If Left(Dtos(dDtSitu), 6 ) <= Left(Dtos(Date()), 6)  .and. Left(Dtos(dDtSitu), 6 ) == PH5->PH5_ANOMES
        cLegenda := "BR_AMARELO"              
    Else 
        cLegenda := ""
    EndIf 

    SX5->(DbSetOrder(1))
    If SX5->(MsSeek(FWxFilial("SX5") + "UA" + PH5->PH5_STATRM))
        cDesStatRM := SX5->X5_DESCRI
    EndIf 

    If Ascan(__aProdCorp, PH5->PH5_PRODUT) > 0
        cCorp := "SIM"    
    EndIf 

    aadd(aAux, {"PH5_CONTRA", PH5->PH5_CONTRA }) // 01
    aadd(aAux, {"PH5_REVISA", PH5->PH5_REVISA }) // 02
    aadd(aAux, {"PH5_NUMERO", PH5->PH5_NUMERO }) // 03
    aadd(aAux, {"PH5_COMPET", PH5->PH5_COMPET }) // 04 
    aadd(aAux, {"PH5_CONDIC", PH5->PH5_CONDIC }) // 05  
    aadd(aAux, {"PH5_CLIENT", PH5->PH5_CLIENT }) // 06
    aadd(aAux, {"PH5_LOJA"  , PH5->PH5_LOJA   }) // 07 
    aadd(aAux, {"PH5_CONDPG", PH5->PH5_CONDPG }) // 08
    aadd(aAux, {"PH5_NOTASE", PH5->PH5_NOTASE }) // 09
    aadd(aAux, {"PH5_MOEDA" , PH5->PH5_MOEDA  }) // 10
    aadd(aAux, {"PH5_MASCCC", PH5->PH5_MASCCC }) // 11
    aadd(aAux, {"PH5_GU"    , PH5->PH5_GU     }) // 12
    aadd(aAux, {"PH5_SEQ"   , PH5->PH5_SEQ    }) // 13
    aadd(aAux, {"PH5_ITEM"  , PH5->PH5_ITEM   }) // 14
    aadd(aAux, {"PH5_PRODUT", PH5->PH5_PRODUT }) // 15
    aadd(aAux, {"PH5_QTDFAT", PH5->PH5_QTDFAT }) // 16
    aadd(aAux, {"PH5_UNIFAT", PH5->PH5_UNIFAT }) // 17
    aadd(aAux, {"PH5_VLRFAT", PH5->PH5_VLRFAT }) // 18
    aadd(aAux, {"PH5_VLFATS", PH5->PH5_VLFATS }) // 19
    aadd(aAux, {"PH5_VLTRIB", PH5->PH5_VLTRIB }) // 20
    aadd(aAux, {"PH5_PROPOS", PH5->PH5_PROPOS }) // 21
    aadd(aAux, {"PH5_REVPRO", PH5->PH5_REVPRO }) // 22
    aadd(aAux, {"PH5_FOLDPR", PH5->PH5_FOLDPR }) // 23
    aadd(aAux, {"PH5_ITMPRO", PH5->PH5_ITMPRO }) // 24
    aadd(aAux, {"PH5_PERRAT", PH5->PH5_PERRAT }) // 25     
    aadd(aAux, {"PH5_STATRM", PH5->PH5_STATRM }) // 26
    aadd(aAux, {"PH5_SITUAC", PH5->PH5_SITUAC }) // 27
    aadd(aAux, {"PH5_RECNO" , PH5->(Recno())  }) // 28
    aadd(aAux, {"PH5_LEGEND", cLegenda        }) // 29 
    aadd(aAux, {"PH5_DESPRO", cDesc           }) // 30
    aadd(aAux, {"PH5_DESCRM", cDesStatRM      }) // 31
    aadd(aAux, {"PH5_CORP"  , cCorp           }) // 32
    
    aadd(aPH5Aux, aClone(aAux))


Return 

Static Function CabecPH6(aPH5Aux, cKeyPH5, cSeqPh5, cAgrLRec, cParcNum, dDtSitu)
    Local aAux       := {}
    Local cMsgPed    := ""
    Local cUnineg    := PH5->PH5_UNINEG
    Local cUniDes    := ""
    Local cLinRec    := ""
    Local cAnoMes    := PH5->PH5_ANOMES
    Local cAMDate    := Left(Dtos(Date()), 6)
    Local cLegenda   := ""
    Local cContra    := CN9->CN9_NUMERO
    Local cRevisa    := CN9->CN9_REVISA
    Local cNumero    := PH5->PH5_NUMERO
    Local cParcela   := ""
    Local cPicPad    := ""
    Local aSM0       := {}
    Local np         := 0
    
    PH6->(DbSetOrder(1))
    If ! PH6->(DBSeek(xFilial("PH6") + cKeyPH5 + cSeqPh5))
        Return .F.
    EndIf
    
    If ! CNA->(CNA_CONTRA+CNA_REVISA+CNA_NUMERO) == PH5->(PH5_CONTRA+PH5_REVISA+PH5_NUMERO)
        CNA->(DbSetOrder(1))
        CNA->(MsSeek(FWxFilial("CNA") + cContra + cRevisa + cNumero))

        cPicPad := Left(CNA->CNA_PICPAD, 2)
        AOM->(DbSetOrder(1))
        AOM->(MsSeek(FWxFilial("AOM") + cAgrLRec + cPicPad))
    EndIf 

    cLinRec := AOM->AOM_DESCRI

    cMsgPed := BuscaPHH(aPH5Aux) //cMsgPed := U_GC067MSG(xFilial("PH6") + cKeyPH5, cSeqPh5)  //carrega mensagem PHH
    cMsgPed := U_GC143MSG(cMsgPed, cUnineg)               //trata a mensagem e corta a msg conforme o limite da unidade
    
    If cAnoMes <= cAMDate
       cLegenda := "BR_VERMELHO"              
    Else 
       cLegenda := "BR_PRETO"
    EndIf

    aSM0 := FWLoadSM0()
    np := Ascan(aSM0, {|x| x[1] + x[2] == cEmpAnt + PH5->PH5_UNINEG})
    If np > 0 
        cUniDes := aSM0[np, 7]
    EndIf 

    cParcela := BuscaPKI(aPH5Aux, cParcNum, dDtSitu)

    If cAnoMes == cAMDate
        aAdd(__aPH61, {})
        nPosPH6 := len(__aPH61)
    ElseIf cAnoMes < cAMDate
        aAdd(__aPH62, {})
        nPosPH6 := len(__aPH62)
    ElseIf cAnoMes > cAMDate
        aAdd(__aPH63, {})
        nPosPH6 := len(__aPH63)    
    EndIf
    
    aadd(aAux, {"PH6_CONTRA", PH6->PH6_CONTRA })
    aadd(aAux, {"PH6_REVISA", PH6->PH6_REVISA })
    aadd(aAux, {"PH6_NUMERO", PH6->PH6_NUMERO })
    aadd(aAux, {"PH6_COMPET", PH6->PH6_COMPET })
    aadd(aAux, {"PH6_CONDIC", PH6->PH6_CONDIC })
    aadd(aAux, {"PH6_CLIENT", PH6->PH6_CLIENT })
    aadd(aAux, {"PH6_LOJA"  , PH6->PH6_LOJA   })
    aadd(aAux, {"PH6_CONDPG", PH6->PH6_CONDPG })
    aadd(aAux, {"PH6_NOTASE", PH6->PH6_NOTASE })
    aadd(aAux, {"PH6_MOEDA" , PH6->PH6_MOEDA  })
    aadd(aAux, {"PH6_MASCCC", PH6->PH6_MASCCC })
    aadd(aAux, {"PH6_GU"    , PH6->PH6_GU     })
    aadd(aAux, {"PH6_SEQ"   , PH6->PH6_SEQ    })
    aadd(aAux, {"PH6_VLRFAT", PH6->PH6_VLRFAT })
    aadd(aAux, {"PH6_STATUS", PH6->PH6_STATUS })
    aadd(aAux, {"PH6_UNINEG", PH6->PH6_UNINEG })
    aadd(aAux, {"PH6_RECNO" , PH6->(Recno())  })
    aadd(aAux, {"PH6_ANOMES", PH6->PH6_ANOMES })
    aadd(aAux, {"PH6_CHECK" , .F.             }) 
    aadd(aAux, {"PH6_CHECK2", .F.             }) 
    aadd(aAux, {"PH6_LEGEND", cLegenda        })
    aadd(aAux, {"PH6_UNIDES", cUniDes         }) 
    aadd(aAux, {"PH6_LINREC", cLinRec         }) 
    aadd(aAux, {"PH6_OBS"   , cMsgPed         }) 
    aadd(aAux, {"PH6_PARC"  , cParcela        }) 
    aadd(aAux, {"PH6_XPOS"  , nPosPH6         }) 
    aadd(aAux, {"PH6_ITENS" , aClone(aPH5Aux) }) 
    
    If cAnoMes == cAMDate
        __aPH61[nPosPH6] := aClone(aAux)
    ElseIf cAnoMes < cAMDate
        __aPH62[nPosPH6] := aClone(aAux)
    ElseIf cAnoMes > cAMDate
        __aPH63[nPosPH6] := aClone(aAux)
    EndIf 

Return .T.


Static Function BuscaPHH(aPH5Aux) 
    Local cContra   := CN9->CN9_NUMERO
    Local cRevisa   := CN9->CN9_REVISA
    Local lMsg      := .F.
    Local cRetMemo  := ""
    Local cRetForm  := ""
    Local cRetMsg   := ""

    Local nPosProp  := 21
    Local nPosPlan  := 3
    Local nPosItem  := 14
    Local nPosCorp  := 32


    PHH->(DbSetOrder(2)) //PHH_FILIAL+PHH_CONTRT+PHH_REVCON+PHH_TPMSG+PHH_STATUS
    PHH->(DbSeek(FwxFilial("PH6")+ cContra + cRevisa))
    While PHH->(! Eof() .and. PHH_FILIAL + PHH_CONTRT + PHH_REVCON == FwxFilial("PH6") + cContra + cRevisa)
        If PHH->PHH_STATUS != "1"  // 1- Ativa, 2-Inativa
            PHH->(DbSkip())
            Loop 
        EndIf
        If dDataBase < PHH->PHH_DTVGDE .or. dDataBase > PHH->PHH_DTVGAT 
            PHH->(DbSkip())
            Loop 
        EndIf 

        If ! Empty(PHH->PHH_COMPET) .and. ! Empty(PHH->PHH_COMPAT)
            If PH5->PH5_ANOMES < CmptoAm(PHH->PHH_COMPET) .OR. PH5->PH5_ANOMES > CmptoAm(PHH->PHH_COMPAT)
                PHH->(DbSkip())
                Loop 
            EndIf 
        EndIF  

        If ! Empty(PHH->PHH_SITEFT) 
            If ! AllTrim(PH5->PH5_UNINEG) == AllTrim(PHH->PHH_SITEFT)
                PHH->(DbSkip())
                Loop 
            EndIf 
        EndIf

        If ! Empty(PHH->PHH_CLIENT) .and. ! Empty(PHH->PHH_LOJA) 
            If !  Alltrim(PH5->(PH5_CLIENT+PH5_LOJA)) == AllTrim(PHH->(PHH_CLIENT + PHH_LOJA)) 
                PHH->(DbSkip())
                Loop 
            EndIf 
        EndIf 

        lMsg    := .F.
        If PHH->PHH_TPMSG == "1"  // proposta
            If Ascan(aPH5Aux, {|x| x[nPosProp, 2] == PHH->PHH_PROPOS}) > 0
                lMsg    := .T. 
            EndIf  
        ElseIf PHH->PHH_TPMSG == "2"  // Contratos
            lMsg    := .T. 
        ElseIf PHH->PHH_TPMSG == "3"  // Corporativos
            If Ascan(aPH5Aux, {|x| x[nPosCorp, 2] == "SIM"}) > 0
                lMsg    := .T. 
            EndIf 
        ElseIf PHH->PHH_TPMSG == "4"  // Item 
            If Ascan(aPH5Aux, {|x| x[nPosPlan, 2] + x[nPosItem, 2]  == PHH->(PHH_NUMPLA + PHH_ITEM)}) > 0
                lMsg    := .T. 
            EndIf  
        EndIf 
        If ! lMsg 
            PHH->(DbSkip())
            Loop 
        EndIf 

        cRetMemo        := ""
        cRetForm    := ""
        If ! Empty(PHH->PHH_FORMUL) // Verifica se a formula foi preenchida
            cRetForm := Alltrim(Formula(PHH->PHH_FORMUL)) 
            If !Empty(cRetForm)
                cRetMsg += AllTrim(cRetForm) + " "
            EndIf 
        EndIf
            
        If ! Empty(PHH->PHH_MSG)   // Aglutina com o que tiver 
           cRetMemo := Alltrim(PHH->PHH_MSG) 
            If ! Empty(cRetMemo)
			    cRetMsg += Alltrim(cRetMemo) + " " 
		    EndIf
        EndIf
        PHH->(DbSkip())
    End 
    
Return cRetMsg

Static Function BuscaPKI(aPH5Aux, cParcNum, dDtSitu)
    Local cParcela := ""
	Local dParcela := ctod("")
    Local nParcela := 0
    Local cCondPg  := PH6->PH6_CONDPG
    Local cAnoMes  := PH6->PH6_ANOMES
    Local nx       := 0 
    Local nPosProp := 21
    Local nPosRevP := 22
    Local nPosFold := 23
    Local nPosItPr := 24 
    Local nPosPRat := 25
    Local cPropos  := ""
    Local cRevPro  := ""
    Local cFolder  := ""
    Local cItemPro := ""
    Local nPerRat  := 0
    Local aParcPKI := {}
    Local np       := 0
    Local aParcela := {}
    Local cRetParc := ""
    
    If Empty(cCondPg)
        Return "" 
    EndIf 

    SE4->(DbSetOrder(1))
    SE4->(MsSeek(xFilial("SE4") + cCondPg))
    If SE4->(Eof() .or. E4_TIPO != "9")
        Return ""
    EndIf 

    If ! Left(Dtos(dDtSitu), 6 ) == cAnoMes
        Return ""
    EndIf 

    aParcPKI := {}
    For nx:= 1 to len(aPH5Aux)
        cPropos  := aPH5Aux[nx, nPosProp, 2]
        cRevPro  := aPH5Aux[nx, nPosRevP, 2]
        cFolder  := aPH5Aux[nx, nPosFold, 2]
        cItemPro := Left(aPH5Aux[nx, nPosItPr, 2], 2)
        nPerRat  := aPH5Aux[nx, nPosPRat, 2]
        
        PKI->(DbSetOrder(1))   //PKI_FILIAL+PKI_PROPOS+PKI_PREVIS+PKI_FOLDER+PKI_ITEM+PKI_PARCEL
        PKI->(DbSeek(xFilial("PKI") + cPropos + cRevPro + cFolder + cItemPro))
        While PKI->(! Eof()  .And. PKI_FILIAL + PKI_PROPOS + PKI_PREVIS + PKI_FOLDER + PKI_ITEM == FWxFilial("PKI") + cPropos + cRevPro + cFolder + cItemPro)
            If PKI->PKI_VALOR <= 0 // Se existir valor
                PKI->(dbSkip())
                Loop
            EndIf 

            cParcela := SubStr(cParcNum, val(PKI->PKI_PARCEL), 1)
            If Empty(cParcela)
                PKI->(dbSkip())
                Loop
            EndIf 

            nParcela := PKI->PKI_VALOR + PKI->PKI_VLTRIB
            If nPerRat > 0
                nParcela := Round(nParcela * nPerRat / 100, 2)
            EndIf 
            dParcela := PKI->PKI_DATA

            np := Ascan(aParcPKI, {|x| x[1] == cParcela})
            If np == 0
                aadd(aParcPKI, {cParcela, dParcela, nParcela})
            Else 
                aParcPKI[np, 3] += nParcela
            EndIf 

            PKI->(dbSkip())
        End
    Next 

    For nx:= 1 to len(aParcPKI)
        aadd(aParcela, {aParcPKI[nx, 2], aParcPKI[nx, 3]})
    Next 

    cRetParc := FwJsonSerialize(aParcela)
    
Return cRetParc 

       


Static Function MtaProdCorp()
    Local aArea   := GetArea()
    Local cAlias  := GetNextAlias()
    Local cQuery  := ""
    
    cQuery := " "
    cQuery += " SELECT DISTINCT SB1.B1_COD PRODUTO " 
    cQuery += " FROM   " + RetSQLName("SB1") + " SB1   " 
    cQuery += " JOIN " + RetSQLName("ZQJ") + " ZQJ ON ZQJ.ZQJ_FILIAL = '" + FwxFilial("ZQJ") + "'   " 
    cQuery += "        AND ZQJ.ZQJ_CODESP = '000001'    " 
    cQuery += "        AND ZQJ.D_E_L_E_T_ = ' '  " 
    cQuery += " JOIN " + RetSQLName("ZQK") + " ZQK ON ZQK.ZQK_FILIAL = '" + FwxFilial("ZQK") + "'   " 
    cQuery += "        AND ZQK.ZQK_CODZQJ = ZQJ.ZQJ_CODIGO   " 
    cQuery += "        AND ZQK.ZQK_GRUPO = SB1.B1_GRUPO   " 
    cQuery += "        AND ZQK.D_E_L_E_T_ = ' '  " 
    cQuery += " WHERE  SB1.B1_FILIAL = '" + FwxFilial("SB1") + "'   " 
    cQuery += "        AND SB1.D_E_L_E_T_ = ' '  " 
    cQuery += " ORDER BY 1  " 
   
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery), cAlias,.F.,.T.)

    (cAlias)->(DbGoTop())
    While ! (cAlias)->(EOF())
        aadd(__aProdCorp, (cAlias)->PRODUTO )
        (cAlias)->(DbSkip())
    End 
    (cAlias)->(DbCloseArea())
    RestArea(aArea)

Return 


Static Function ModelDef()
    Local cLstPH6 := 'PH6_CONTRA|PH6_REVISA|PH6_NUMERO|PH6_COMPET|PH6_CONDIC|PH6_CLIENT|PH6_LOJA|PH6_CONDPG|PH6_NOTASE|PH6_MOEDA|PH6_MASCCC|PH6_GU|PH6_SEQ|PH6_VLRFAT|PH6_STATUS|PH6_UNIDES|PH6_UNINEG|PH6_RECNO|PH6_ANOMES|'
    Local cLstPH5 := 'PH5_CONTRA|PH5_REVISA|PH5_NUMERO|PH5_COMPET|PH5_CONDIC|PH5_CLIENT|PH5_LOJA|PH5_CONDPG|PH5_NOTASE|PH5_MOEDA|PH5_MASCCC|PH5_GU|PH5_SEQ|PH5_ITEM|PH5_PRODUT|PH5_QTDFAT|PH5_UNIFAT|PH5_VLRFAT|PH5_VLFATS|PH5_VLTRIB|PH5_PROPOS|PH5_STATRM|PH5_SITUAC|PH5_RECNO|'

    Local oModel    := Nil
    Local oStrCN9   := FWFormStruct(1,'CN9',{|cCampo|  AllTrim(cCampo) $ 'CN9_NUMERO|CN9_REVISA' })
    Local oStrPH61  := FWFormStruct(1,'PH6',{|cCampo|  AllTrim(cCampo) + "|" $ cLstPH6})
    Local oStrPH51  := FWFormStruct(1,'PH5',{|cCampo|  AllTrim(cCampo) + "|" $ cLstPH5})
    Local oStrPH62  := FWFormStruct(1,'PH6',{|cCampo|  AllTrim(cCampo) + "|" $ cLstPH6})
    Local oStrPH52  := FWFormStruct(1,'PH5',{|cCampo|  AllTrim(cCampo) + "|" $ cLstPH5})
    Local oStrPH63  := FWFormStruct(1,'PH6',{|cCampo|  AllTrim(cCampo) + "|" $ cLstPH6})
    Local oStrPH53  := FWFormStruct(1,'PH5',{|cCampo|  AllTrim(cCampo) + "|" $ cLstPH5})
    
    
    Local aGatilho  := {}
    Local oEvent    := TGCVA143E():New()
    Local oModPH61   := Nil
    Local oModPH51   := Nil
    Local oModPH62   := Nil
    Local oModPH52   := Nil
    Local oModPH63   := Nil
    Local oModPH53   := Nil

    // personalização das estruturas
    AddFldPH6(oStrPH61, 1)
    AddFldPH5(oStrPH51, 1)
    AddFldPH6(oStrPH62, 1)
    AddFldPH5(oStrPH52, 1)
    AddFldPH6(oStrPH63, 1)
    AddFldPH5(oStrPH53, 1)

    oStrPH61:SetProperty("PH6_CONDPG", MODEL_FIELD_VALID, FWBuildFeature(STRUCT_FEATURE_VALID, 'U_GV143G05(a,b,c,d)'))
    oStrPH62:SetProperty("PH6_CONDPG", MODEL_FIELD_VALID, FWBuildFeature(STRUCT_FEATURE_VALID, 'U_GV143G05(a,b,c,d)'))
    oStrPH63:SetProperty("PH6_CONDPG", MODEL_FIELD_VALID, FWBuildFeature(STRUCT_FEATURE_VALID, 'U_GV143G05(a,b,c,d)'))
    
    oStrPH51:SetProperty("PH5_VLRFAT", MODEL_FIELD_VALID, FWBuildFeature(STRUCT_FEATURE_VALID, 'U_GV143G03(a,b,c,d)'))
    oStrPH52:SetProperty("PH5_VLRFAT", MODEL_FIELD_VALID, FWBuildFeature(STRUCT_FEATURE_VALID, 'U_GV143G03(a,b,c,d)'))
    oStrPH53:SetProperty("PH5_VLRFAT", MODEL_FIELD_VALID, FWBuildFeature(STRUCT_FEATURE_VALID, 'U_GV143G03(a,b,c,d)'))

    //aGatilho := FwStruTrigger(cDom, cCDom, cRegra, lSeek, cAlias, nOrdem, cChave, cCondic) 
    //aGatilho[1] -> cIdField
    //aGatilho[2] -> cTargetIdField
    //aGatilho[3] -> bPre
    //aGatilho[4] -> bSetValue
    //AddTrigger(cIdField, cTargetIdField, bPre, bSetValue)    

    aGatilho := FwStruTrigger('PH6_CHECK', 'PH6_CHECK2', 'U_GV143G02("PH6_CHECK2", 1)', .F.)
    oStrPH61:AddTrigger(aGatilho[1], aGatilho[2], aGatilho[3], aGatilho[4] )

    aGatilho := FwStruTrigger('PH5_VLRFAT', 'PH5_UNIFAT', 'U_GV143G02("PH5_UNIFAT", 1)', .F.)
    oStrPH51:AddTrigger(aGatilho[1], aGatilho[2], aGatilho[3], aGatilho[4] )

    aGatilho := FwStruTrigger('PH5_VLRFAT', 'PH5_VLFATS', 'U_GV143G02("PH5_VLFATS", 1)', .F.)
    oStrPH51:AddTrigger(aGatilho[1], aGatilho[2], aGatilho[3], aGatilho[4] )

    aGatilho := FwStruTrigger('PH5_VLRFAT', 'PH5_VLTRIB', 'U_GV143G02("PH5_VLTRIB", 1)', .F.)
    oStrPH51:AddTrigger(aGatilho[1], aGatilho[2], aGatilho[3], aGatilho[4] )

    aGatilho := FwStruTrigger('PH6_CHECK', 'PH6_CHECK2', 'U_GV143G02("PH6_CHECK2", 2)', .F.)
    oStrPH62:AddTrigger(aGatilho[1], aGatilho[2], aGatilho[3], aGatilho[4] )

    aGatilho := FwStruTrigger('PH5_VLRFAT', 'PH5_UNIFAT', 'U_GV143G02("PH5_UNIFAT", 2)', .F.)
    oStrPH52:AddTrigger(aGatilho[1], aGatilho[2], aGatilho[3], aGatilho[4] )

    aGatilho := FwStruTrigger('PH5_VLRFAT', 'PH5_VLFATS', 'U_GV143G02("PH5_VLFATS", 2)', .F.)
    oStrPH52:AddTrigger(aGatilho[1], aGatilho[2], aGatilho[3], aGatilho[4] )
    aGatilho := FwStruTrigger('PH5_VLRFAT', 'PH5_VLTRIB', 'U_GV143G02("PH5_VLTRIB", 3)', .F.)
    oStrPH52:AddTrigger(aGatilho[1], aGatilho[2], aGatilho[3], aGatilho[4] )

    aGatilho := FwStruTrigger('PH6_CHECK', 'PH6_CHECK2', 'U_GV143G02("PH6_CHECK2", 3)', .F.)
    oStrPH63:AddTrigger(aGatilho[1], aGatilho[2], aGatilho[3], aGatilho[4] )

    aGatilho := FwStruTrigger('PH5_VLRFAT', 'PH5_UNIFAT', 'U_GV143G02("PH5_UNIFAT", 3)', .F.)
    oStrPH53:AddTrigger(aGatilho[1], aGatilho[2], aGatilho[3], aGatilho[4] )
    
    aGatilho := FwStruTrigger('PH5_VLRFAT', 'PH5_VLFATS', 'U_GV143G02("PH5_VLFATS", 3)', .F.)
    oStrPH53:AddTrigger(aGatilho[1], aGatilho[2], aGatilho[3], aGatilho[4] )
    aGatilho := FwStruTrigger('PH5_VLRFAT', 'PH5_VLTRIB', 'U_GV143G02("PH5_VLTRIB", 3)', .F.)
    oStrPH53:AddTrigger(aGatilho[1], aGatilho[2], aGatilho[3], aGatilho[4] )


    // persoanalização do modelos
    oModel:= MPFormModel():New('TGCV143MVC')
    oModel:AddFields('CN9MASTER',, oStrCN9) 

    oModel:AddGrid('PH6MOD1','CN9MASTER', oStrPH61 ,,,,, {|oGrid| LeCab(oGrid, 1)}         )
    oModel:AddGrid('PH5MOD1','PH6MOD1'  , oStrPH51 ,,,,, {|oGrid| LeItens(oGrid, oModel, 1 )})

    oModel:AddGrid('PH6MOD2','CN9MASTER', oStrPH62 ,,,,, {|oGrid| LeCab(oGrid, 2)}         )
    oModel:AddGrid('PH5MOD2','PH6MOD2'  , oStrPH52 ,,,,, {|oGrid| LeItens(oGrid, oModel, 2 )})

    oModel:AddGrid('PH6MOD3','CN9MASTER', oStrPH63 ,,,,, {|oGrid| LeCab(oGrid, 3)}         )
    oModel:AddGrid('PH5MOD3','PH6MOD3'  , oStrPH53 ,,,,, {|oGrid| LeItens(oGrid, oModel, 3 )})
    
    oModPH61 := oModel:GetModel('PH6MOD1')
    oModPH61:SetDescription("Competências") 
    oModPH61:SetNoInsertLine(.T.)
    oModPH61:SetNoDeleteLine(.T.)
    oModPH61:SetNoUpdateLine(.F.)
    oModPH61:SetOptional( .T. )
    oModPH61:SetOnlyQuery(.T.)

    
    oModPH51 := oModel:GetModel('PH5MOD1')
    oModPH51:SetDescription("Itens") 
    oModPH51:SetNoInsertLine(.T.)
    oModPH51:SetNoDeleteLine(.T.)
    oModPH51:SetNoUpdateLine(.F.)
    oModPH51:SetOptional( .T. )
    oModPH51:SetOnlyQuery(.T.)

    oModPH62 := oModel:GetModel('PH6MOD2')
    oModPH62:SetDescription("Competências") 
    oModPH62:SetNoInsertLine(.T.)
    oModPH62:SetNoDeleteLine(.T.)
    oModPH62:SetNoUpdateLine(.F.)
    oModPH62:SetOptional( .T. )
    oModPH62:SetOnlyQuery(.T.)

    
    oModPH52 := oModel:GetModel('PH5MOD2')
    oModPH52:SetDescription("Itens") 
    oModPH52:SetNoInsertLine(.T.)
    oModPH52:SetNoDeleteLine(.T.)
    oModPH52:SetNoUpdateLine(.F.)
    oModPH52:SetOptional( .T. )
    oModPH52:SetOnlyQuery(.T.)

    oModPH63 := oModel:GetModel('PH6MOD3')
    oModPH63:SetDescription("Competências") 
    oModPH63:SetNoInsertLine(.T.)
    oModPH63:SetNoDeleteLine(.T.)
    oModPH63:SetNoUpdateLine(.F.)
    oModPH63:SetOptional( .T. )
    oModPH63:SetOnlyQuery(.T.)

    
    oModPH53 := oModel:GetModel('PH5MOD3')
    oModPH53:SetDescription("Itens") 
    oModPH53:SetNoInsertLine(.T.)
    oModPH53:SetNoDeleteLine(.T.)
    oModPH53:SetNoUpdateLine(.F.)
    oModPH53:SetOptional( .T. )
    oModPH53:SetOnlyQuery(.T.)

    oModel:SetDescription( Alltrim(CN9->CN9_NUMERO)+'/'+Alltrim(CN9->CN9_REVISA) )
    oModel:SetActivate({|oModel| U_GV143G04(oModel),  .T. })
    oModel:InstallEvent("TGCVA143E", , oEvent)

Return oModel


Static Function ViewDef()

    Local oModel    := FWLoadModel('TGCVA143')
    Local oView     := FWFormView():New()
    Local oRowHeight:= TISetRowHeight():New() // Classe para ajuste na Altura do Grid
    Local oStrPH6   := FWFormStruct(2,'PH6',{|cCampo|  AllTrim(cCampo) $ 'PH6_CLIENT|PH6_COMPET|PH6_ANOMES|PH6_LOJA|PH6_CONDPG|PH6_VLRFAT|PH6_UNINEG|PH6_UNIDES|PH6_SEQ|PH6_ULTIMO'})
    Local oStrPH5   := FWFormStruct(2,'PH5',{|cCampo|  AllTrim(cCampo) $ 'PH5_COMPET|PH5_PROPOS|PH5_PRODUT|PH5_DESPRO|PH5_QTDFAT|PH5_UNIFAT|PH5_VLRFAT|PH5_VLFATS|PH5_VLTRIB|PH5_ULTIMO|PH5_STATRM|PH5_SITUAC|'})
    Local cMesAno   := AmtoCmp(Left(Dtos(Date()), 6))
    
    AddFldPH6(oStrPH6, 2)
    AddFldPH5(oStrPH5, 2)

    AltStru(oStrPH6, oStrPH5)

    oView:SetModel( oModel )
    oView:AddGrid('VIEW_PH61', oStrPH6, 'PH6MOD1')
    oView:AddGrid('VIEW_PH51', oStrPH5, 'PH5MOD1')
    
    oView:AddGrid('VIEW_PH62', oStrPH6, 'PH6MOD2')
    oView:AddGrid('VIEW_PH52', oStrPH5, 'PH5MOD2')

    oView:AddGrid('VIEW_PH63', oStrPH6, 'PH6MOD3')
    oView:AddGrid('VIEW_PH53', oStrPH5, 'PH5MOD3')

    oView:CreateFolder('PASTAS')
    oView:AddSheet( 'PASTAS', 'ABA01', cMesAno    )
    oView:AddSheet( 'PASTAS', 'ABA02', 'Represado')
    oView:AddSheet( 'PASTAS', 'ABA03', 'Futuro'   )

    oView:CreateHorizontalBox('BOXPH61'  ,  45 ,,, 'PASTAS', 'ABA01') 
    oView:CreateHorizontalBox('BOXLEG1'  ,  5  ,,, 'PASTAS', 'ABA01')
    oView:CreateHorizontalBox('BOXPH51'  ,  45 ,,, 'PASTAS', 'ABA01')
    oView:CreateHorizontalBox('BOXLE21'  ,  5  ,,, 'PASTAS', 'ABA01')
    

        oView:SetOwnerView('VIEW_PH61' , 'BOXPH61' )
        oView:SetOwnerView('VIEW_PH51' , 'BOXPH51' )
        oView:EnableTitleView('VIEW_PH61' , oModel:GetModel('PH6MOD1'):GetDescription())
        oView:EnableTitleView('VIEW_PH51' , oModel:GetModel('PH5MOD1'):GetDescription())
        oView:AddOtherObject('PANLEG1',{|oP| PLeg1(oP, 1) }, ,,  .F. )
        oView:SetOwnerView('PANLEG1' ,'BOXLEG1')
        oView:AddOtherObject('PANLE21',{|oP| PLeg2(oP, 1) }, ,,  .F. )
        oView:SetOwnerView('PANLE21' ,'BOXLE21')
    

    oView:CreateHorizontalBox('BOXPH62'  ,  45 ,,, 'PASTAS', 'ABA02') 
    oView:CreateHorizontalBox('BOXLEG2'  ,  5  ,,, 'PASTAS', 'ABA02')
    oView:CreateHorizontalBox('BOXPH52'  ,  45 ,,, 'PASTAS', 'ABA02')
    oView:CreateHorizontalBox('BOXLE22'  ,  5  ,,, 'PASTAS', 'ABA02')
        oView:SetOwnerView('VIEW_PH62' , 'BOXPH62' )
        oView:SetOwnerView('VIEW_PH52' , 'BOXPH52' )
        oView:EnableTitleView('VIEW_PH62' , oModel:GetModel('PH6MOD2'):GetDescription())
        oView:EnableTitleView('VIEW_PH52' , oModel:GetModel('PH5MOD2'):GetDescription())
        oView:AddOtherObject('PANLEG2',{|oP| PLeg1(oP, 2) },,, .F. )
        oView:SetOwnerView('PANLEG2' ,'BOXLEG2')

        oView:AddOtherObject('PANLE22',{|oP| PLeg2(oP, 2) },,, .F. )
        oView:SetOwnerView('PANLE22' ,'BOXLE22')

    oView:CreateHorizontalBox('BOXPH63'  ,  45 ,,, 'PASTAS', 'ABA03') 
    oView:CreateHorizontalBox('BOXLEG3'  ,  5  ,,, 'PASTAS', 'ABA03')
    oView:CreateHorizontalBox('BOXPH53'  ,  45 ,,, 'PASTAS', 'ABA03')
    oView:CreateHorizontalBox('BOXLE23'  ,  5  ,,, 'PASTAS', 'ABA03')
        oView:SetOwnerView('VIEW_PH63' , 'BOXPH63' )
        oView:SetOwnerView('VIEW_PH53' , 'BOXPH53' )
        oView:EnableTitleView('VIEW_PH63' , oModel:GetModel('PH6MOD3'):GetDescription())
        oView:EnableTitleView('VIEW_PH53' , oModel:GetModel('PH5MOD3'):GetDescription())
        
        oView:AddOtherObject('PANLEG3',{|oP| PLeg1(oP, 3) },,, .F.)
        oView:SetOwnerView('PANLEG3' ,'BOXLEG3')
        oView:AddOtherObject('PANLE23',{|oP| PLeg2(oP, 3) },,, .F.)
        oView:SetOwnerView('PANLE23' ,'BOXLE23')


    oRowHeight:SetRowHeigh(@oView)
    oView:AddUserButton("Marca/Desmarca", 'CLIPS',{|| U_GV143G09(oView)}) 

    oView:SetViewProperty("VIEW_PH61", "GRIDFILTER", {.T.})
    oView:SetViewProperty("VIEW_PH62", "GRIDFILTER", {.T.})
    oView:SetViewProperty("VIEW_PH63", "GRIDFILTER", {.T.})
    oView:SetViewProperty("VIEW_PH51", "GRIDFILTER", {.T.})
    oView:SetViewProperty("VIEW_PH52", "GRIDFILTER", {.T.})
    oView:SetViewProperty("VIEW_PH53", "GRIDFILTER", {.T.})
    oView:SetCloseOnOk({|| .T. })
    

Return oView


Static Function AltStru(oStrPH6, oStrPH5)
    Local cOrdem    := '00'

    cOrdem  := '00'
    oStrPH6:SetProperty('PH6_CHECK'   ,MVC_VIEW_ORDEM,cOrdem)
    oStrPH6:SetProperty('PH6_CHECK2'  ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))
    oStrPH6:SetProperty('PH6_LEGEND'  ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))
    oStrPH6:SetProperty('PH6_LINREC'  ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))
    oStrPH6:SetProperty('PH6_COMPET'  ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))
    oStrPH6:SetProperty('PH6_ANOMES'  ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))
      
    
    oStrPH6:SetProperty('PH6_SEQ'     ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))
    oStrPH6:SetProperty('PH6_CLIENT'  ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))
    oStrPH6:SetProperty('PH6_LOJA'    ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))
    oStrPH6:SetProperty('PH6_OBS'     ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))    
    oStrPH6:SetProperty('PH6_VLRFAT'  ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))
    oStrPH6:SetProperty('PH6_CONDPG'  ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))
    oStrPH6:SetProperty('PH6_UNINEG'  ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))
    oStrPH6:SetProperty('PH6_UNIDES'  ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))
    oStrPH6:SetProperty('PH6_ULTIMO'  ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))
    oStrPH6:SetProperty('PH6_PARC'    ,MVC_VIEW_ORDEM,(cOrdem:=Soma1(cOrdem)))    

    oStrPH6:SetProperty('*',  MVC_VIEW_CANCHANGE, .F.)
    oStrPH6:SetProperty('PH6_CHECK' , MVC_VIEW_CANCHANGE, .T.)
    oStrPH6:SetProperty('PH6_CHECK2', MVC_VIEW_CANCHANGE, .T.)
    oStrPH6:SetProperty('PH6_OBS'   , MVC_VIEW_CANCHANGE, .T.)
    oStrPH6:SetProperty('PH6_CONDPG', MVC_VIEW_CANCHANGE, .T.)  

    oStrPH6:RemoveField('PH6_RECNO')
    oStrPH6:RemoveField('PH6_PARC')
    oStrPH6:RemoveField('PH6_XPOS')
    
    
    cOrdem  := '00'
    oStrPH5:SetProperty("*",  MVC_VIEW_CANCHANGE, .F.)
    oStrPH5:SetProperty("PH5_VLRFAT", MVC_VIEW_CANCHANGE, .T.) 
       
    oStrPH5:SetProperty("PH5_LEGEND", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))
    oStrPH5:SetProperty("PH5_COMPET", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))
    oStrPH5:SetProperty("PH5_PRODUT", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))
    oStrPH5:SetProperty("PH5_DESPRO", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))
    oStrPH5:SetProperty("PH5_QTDFAT", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))
    oStrPH5:SetProperty("PH5_UNIFAT", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))
    oStrPH5:SetProperty("PH5_VLRFAT", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))
    oStrPH5:SetProperty("PH5_VLFATS", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))
    oStrPH5:SetProperty("PH5_VLTRIB", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))
    oStrPH5:SetProperty("PH5_PROPOS", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))
    oStrPH5:SetProperty("PH5_STATRM", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))    
    oStrPH5:SetProperty("PH5_DESCRM", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))  
    oStrPH5:SetProperty("PH5_SITUAC", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))  
    oStrPH5:SetProperty("PH5_ULTIMO", MVC_VIEW_ORDEM, (cOrdem:=Soma1(cOrdem)))

    oStrPH5:RemoveField('PH5_RECNO')


Return 



Static Function PLeg1(oDlg, nFolder) 

    
    If nFolder == 1 .or. nFolder == 2
        TBitmap():New ( 2, 0.5, 010, 010, "BR_VERMELHO.PNG", Nil, .T., oDlg, Nil, Nil, .F., .F., Nil, Nil, Nil, Nil, .T., Nil, Nil, Nil, Nil )
        TSay():New( 002, 011, { || "Em aberto"    }, oDlg, Nil, Nil, Nil, Nil, Nil, .T., Nil, Nil, 060, 010, Nil, Nil, Nil, Nil, Nil, .T. )   
    Else 
        TBitmap():New ( 2, 0.5, 010, 010, "BR_PRETO.PNG"   , Nil, .T., oDlg, Nil, Nil, .F., .F., Nil, Nil, Nil, Nil, .T., Nil, Nil, Nil, Nil )
        TSay():New( 002, 011, { || "Futuro"       }, oDlg, Nil, Nil, Nil, Nil, Nil, .T., Nil, Nil, 060, 010, Nil, Nil, Nil, Nil, Nil, .T. )    
    EndIf 

Return 

Static Function PLeg2(oDlg, nFolder) 

    TBitmap():New ( 2, 0.5, 010, 010, "BR_AMARELO.PNG" , Nil, .T., oDlg, Nil, Nil, .F., .F., Nil, Nil, Nil, Nil, .T., Nil, Nil, Nil, Nil )
    TSay():New( 002, 011, { || "Proposta Nova"}, oDlg, Nil, Nil, Nil, Nil, Nil, .T., Nil, Nil, 060, 010, Nil, Nil, Nil, Nil, Nil, .T. )          

Return 


Static Function AddFldPH6(oStrPH6, nOpc)

    If nOpc == 1 // Model
        //                 TITULO CAMPO        , ToolTip             ,  ID         , TIPO, TAM ,DEC , validação                            , When                                  , lista , obrigat, inicialização do campo                       , campos chave, altera, virtual
        oStrPH6:AddField("Gerar Pedido"      , "Gerar Pedido"      , 'PH6_CHECK' , 'L' , 1   , 0  , Nil                                   , {|a,b,c,d,e| VldCheck(a,b,c,d,e)}     , NIL   , .F.    , FwBuildFeature( STRUCT_FEATURE_INIPAD,'.F.') , .F.         , .F.   , .F.)            
        oStrPH6:AddField("Liberado"          , "Liberado"          , 'PH6_CHECK2', 'L' , 1   , 0  , Nil                                   , {|| .T.}                              , NIL   , .F.    , FwBuildFeature( STRUCT_FEATURE_INIPAD,'.F.') , .F.         , .F.   , .F.)            
        oStrPH6:AddField(""                  , ""                  , "PH6_LEGEND", "C" , 15  , 0  , NIL                                   , {|| .T.}                              , NIL   , .F.    , nil                                          , NIL         , .T.   , .T.)   
        oStrPH6:AddField("Linha Receita"     , "Linha Receita"     , 'PH6_LINREC', 'C' , 30  , 0  , Nil                                   , NIL                                   , Nil   , .F.    , Nil                                          , .T.         , .T.   , .T.)
        oStrPH6:AddField(""                  , ""                  , 'PH6_ULTIMO', "C" , 15  , 0  , NIL                                   , {|| .T.}                              , NIL   , .F.    , nil                                          , NIL         , .T.   , .T.)   
        oStrPH6:AddField("Recno PH6"         , "Recno PH6"         , 'PH6_RECNO' , 'N' , 16  , 0  , Nil                                   , NIL                                   , NIL   , .F.    , NIL                                          , .T.         , .T.   , .T.) 
        oStrPH6:AddField("Msg Nota X Lin.Rec", "Msg Nota X Lin.Rec", 'PH6_OBS'   , 'M' , 10  , 0  , { |a,b,c,d,e| VldMsg(a,b, c,d,e) }    , NIL                                   , NIL   , .F.    , Nil                                          , .F.         , .F.   , .F.) 
        oStrPH6:AddField("Parcelas"          , "Parcelas"          , 'PH6_PARC'  , 'M' , 10  , 0  , NIL                                   , NIL                                   , NIL   , .F.    , Nil                                          , .F.         , .F.   , .F.) 
        oStrPH6:AddField("Posicao"           , "Posicao"           , 'PH6_XPOS'  , 'N' , 16  , 0  , Nil                                   , NIL                                   , NIL   , .F.    , NIL                                          , .T.         , .T.   , .T.) 
    Else // View
        //                 Nome campo  , ordem, Titulo              , Descricação         , Helps , Tipo, Picture, Picture var ,  F3, altera, pasta , agru, combo, max combo, IniBrow, virtual , Picture, ???)   
        oStrPH6:AddField('PH6_CHECK' ,'00'  , "Gerar Pedido"      , "Gerar Pedido"      , NIL   , 'L' , ''     , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
        oStrPH6:AddField('PH6_CHECK2' ,'00' , "Liberado"          , "Liberado"          , NIL   , 'L' , ''     , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
        oStrPH6:AddField("PH6_LEGEND","01"  , ""                  , ""                  , NIL   , "C" , "@BMP" , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
        oStrPH6:AddField('PH6_LINREC','02'  , "Linha Receita"     , "Linha Receita"     , NIL   , 'C' , '@!'   , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
        oStrPH6:AddField('PH6_ULTIMO','05'  , ""                  , ""                  , NIL   , 'N' , ''     , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
        oStrPH6:AddField('PH6_RECNO' ,'06'  , "Recno PH6"         , "Recno PH6"         , NIL   , 'N' , ''     , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
        oStrPH6:AddField('PH6_OBS'   ,'07'  , "Msg Nota X Lin.Rec", "Msg Nota X Lin.Rec", NIL   , 'N' , ''     , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
        oStrPH6:AddField('PH6_PARC'  ,'08'  , "Parcelas"          , "Parcelas"          , NIL   , 'N' , ''     , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
        oStrPH6:AddField('PH6_XPOS'  ,'09'  , "Posicao"           , "Posicao"           , NIL   , 'N' , ''     , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
    EndIf  

Return



Static Function AddFldPH5(oStrPH5, nOpc)

    If nOpc == 1 // Model
        //                 TITULO CAMPO        , ToolTip             ,  ID         , TIPO, TAM ,DEC , validação                            , When                                  , lista , obrigat, inicialização do campo                       , campos chave, altera, virtual
        oStrPH5:AddField(""                  , ""                  , "PH5_LEGEND", "C" , 15  , 0  , NIL                                   , {|| .T.}                              , NIL   , .F.    , nil                                          , NIL         , .T.   , .T.)   
        oStrPH5:AddField("Descrição"         , "Descrição"         , 'PH5_DESPRO', 'C' , 100 , 0  , Nil                                   , NIL                                   , Nil   , .F.    , Nil                                          , .T.         , .T.   , .T.)
        oStrPH5:AddField("Descrição StatusRM", "Descrição StatusRM", 'PH5_DESCRM', 'C' , 50  , 0  , Nil                                   , NIL                                   , Nil   , .F.    , Nil                                          , .T.         , .T.   , .T.)                
        oStrPH5:AddField("Recno PH6"         , "Recno PH5"         , 'PH5_RECNO' , 'N' , 16  , 0  , Nil                                   , NIL                                   , NIL   , .F.    , NIL                                          , .T.         , .T.   , .T.) 
        oStrPH5:AddField(""                  , ""                  , 'PH5_ULTIMO', "C" , 15  , 0  , NIL                                   , {|| .T.}                              , NIL   , .F.    , nil                                          , NIL         , .T.   , .T.)           
    Else // View
        //                 Nome campo  , ordem, Titulo              , Descricação         , Helps , Tipo, Picture, Picture var ,  F3, altera, pasta , agru, combo, max combo, IniBrow, virtual , Picture, ???)   
        oStrPH5:AddField("PH5_LEGEND","01"  , ""                  , ""                  , NIL   , "C" , "@BMP" , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
        oStrPH5:AddField('PH5_DESPRO','02'  , "Descrição"         , "Descrição"         , NIL   , 'C' , '@!'   , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
        oStrPH5:AddField('PH5_DESCRM','04'  , "Descrição StatusRM", "Descrição StatusRM", NIL   , 'C' , '@!'   , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
        oStrPH5:AddField('PH5_RECNO' ,'04'  , "Recno PH5"         , "Recno PH5"         , NIL   , 'N' , ''     , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
        oStrPH5:AddField('PH5_ULTIMO','04'  , ""                  , ""                  , NIL   , 'N' , ''     , NIL         , NIL, .T.   , NIL   , NIL , NIL  , NIL      , NIL    , .T.     , NIL    , NIL )        
    EndIf  

Return

Static Function LeCab(oGrid, nFolder)
    Local aRet      := {}
    Local aAux      := {}
    Local oEstrut   := oGrid:GetStruct()
    Local aCmpGrid  := oEstrut:GetFields()
    Local cCampo    := ""
    Local uConteudo := NIL 
    Local nx        := 0
    Local nc        := 0
    Local aPH6      := {}

    If nFolder == 1
        aPH6      := aClone(__aPH61)
    ElseIf nFolder == 2
        aPH6      := aClone(__aPH62)
    ElseIf nFolder == 3
        aPH6      := aClone(__aPH63)
    EndIf 

    For nx := 1 to len(aPH6) 
        
        aAux := {}
        For nc := 1 to len(aCmpGrid)
            cCampo    := aCmpGrid[nC, 3]

            uConteudo := GetItens(cCampo, aPH6[nx])
            aadd(aAux, uConteudo)
        Next 
        aAdd(aRet,{0 , aClone(aAux)})
    Next 

Return aRet

Static Function LeItens(oGrid, oModel, nFolder)
    Local aRet      := {}
    Local aAux      := {}
    Local oEstrut   := oGrid:GetStruct()
    Local aCmpGrid  := oEstrut:GetFields()
    Local oObjCrn   := oModel:GetModel('PH6MOD' + Str(nFolder, 1))
    
    Local cCampo    := ""
    Local uConteudo := NIL 
    Local nx        := 0
    Local nc        := 0
    Local aPH5      := {}

    Local nPosPH6   := oObjCrn:GetValue('PH6_XPOS')
    Local nPosUlt   := 0

    If nFolder == 1 
        If nPosPH6 > 0
            nPosUlt := len(__aPH61[nPosPH6])
            aPH5    := aClone(__aPH61[nPosPH6, nPosUlt, 2])
        EndIf 
    ElseIf nFolder == 2 
        If nPosPH6 > 0
            nPosUlt := len(__aPH62[nPosPH6])
            aPH5    := aClone(__aPH62[nPosPH6, nPosUlt, 2])
        EndIf
    ElseIf nFolder == 3 
    
        If nPosPH6 > 0
            nPosUlt := len(__aPH63[nPosPH6])
            aPH5    := aClone(__aPH63[nPosPH6, nPosUlt, 2])
        EndIf
    EndIf 

    For nx := 1 to len(aPH5)
        aAux := {}
        For nc := 1 to len(aCmpGrid)
            cCampo    := aCmpGrid[nC, 3]
            uConteudo := GetItens(cCampo, aPH5[nx])
            aadd(aAux, uConteudo)
        Next 
        aAdd(aRet,{0 , aClone(aAux)})
    Next 

Return aRet


Static Function MtaQry()
    Local cSql := ""
    Local cContra := CN9->CN9_NUMERO
    Local cRevisa := CN9->CN9_REVISA

    cSql := " SELECT PH5.R_E_C_N_O_ RECNO,PH5_CONTRA,PH5_REVISA,PH5_NUMERO,PH5_COMPET,PH5_CONDIC,PH5_CLIENT,PH5_LOJA,PH5_CONDPG,PH5_NOTASE,PH5_MOEDA,PH5_MASCCC,PH5_GU,PH5_SEQ,CNB_DTSITU,CNB_DESCRI "
    cSql += "   FROM " + RetSQlName("PH6") + " PH6 "    
    cSql += " INNER JOIN " + RetSqlName("PH5") + " PH5 " 
    cSql += "         ON PH5.PH5_FILIAL = '" + FWxFilial("PH5") + "' " 
    cSql += "        AND PH5.PH5_CONTRA = PH6.PH6_CONTRA " 
    cSql += "        AND PH5.PH5_REVISA = PH6.PH6_REVISA " 
    cSql += "        AND PH5.PH5_NUMERO = PH6.PH6_NUMERO " 
    cSql += "        AND PH5.PH5_COMPET = PH6.PH6_COMPET " 
    cSql += "        AND PH5.PH5_CONDIC = PH6.PH6_CONDIC " 
    cSql += "        AND PH5.PH5_CLIENT = PH6.PH6_CLIENT " 
    cSql += "        AND PH5.PH5_LOJA   = PH6.PH6_LOJA " 
    cSql += "        AND PH5.PH5_CONDPG = PH6.PH6_CONDPG " 
    cSql += "        AND PH5.PH5_NOTASE = PH6.PH6_NOTASE " 
    cSql += "        AND PH5.PH5_MOEDA  = PH6.PH6_MOEDA " 
    cSql += "        AND PH5.PH5_MASCCC = PH6.PH6_MASCCC " 
    cSql += "        AND PH5.PH5_GU     = PH6.PH6_GU " 
    cSql += "        AND PH5.PH5_SEQ    = PH6.PH6_SEQ " 
    cSql += "        AND PH5.D_E_L_E_T_ = ' ' " 
    cSql += " INNER JOIN " + RetSQlName("CNB") + " CNB "  
    cSql += "         ON CNB.CNB_FILIAL = '"+ FWxFilial("CNB") + "' "    
    cSql += "        AND CNB.CNB_CONTRA = PH6.PH6_CONTRA " 
    cSql += "        AND CNB.CNB_REVISA = PH6.PH6_REVISA " 
    cSql += "        AND CNB.CNB_NUMERO = PH6.PH6_NUMERO " 
    cSql += "        AND CNB.CNB_ITEM = PH5_ITEM "         
    cSql += "        AND CNB.D_E_L_E_T_ = ' ' " 
    cSql += "  LEFT JOIN "+ RetSQlName("PHN") +" PHN " 
	cSql += "         ON PHN.PHN_FILIAL = '"+ FWxFilial("PHN") +"' " 
	cSql += "        AND PHN.PHN_CONTRA = CNB.CNB_CONTRA " 
	cSql += "        AND PHN.PHN_REVISA = CNB.CNB_REVISA " 
	cSql += "        AND PHN.PHN_NUMERO = CNB.CNB_NUMERO " 
	cSql += "        AND PHN.PHN_ITEM = CNB.CNB_ITEM " 
	cSql += "        AND PHN.D_E_L_E_T_ = ' ' " 
    cSql += " WHERE PH6.PH6_FILIAL = '" + FWxFilial("PH6") + "' "   
    cSql += "       AND PH6.PH6_CONTRA = '" + cContra + "' " 
    cSql += "       AND PH6.PH6_REVISA = '" + cRevisa + "' " 
    cSql += "       AND PH6.PH6_NUMMED = ' ' " 
    cSql += "       AND PH6.PH6_PEDVEN = ' ' " 
    cSql += "       AND PH6.PH6_VLRFAT > 0 "
    cSql += "       AND PH6.PH6_MSBLQL <> '1' "
    cSql += "       AND (CNB.CNB_SITUAC IN ('A','P') OR (CNB.CNB_SITUAC = 'O' AND PH5.PH5_ANOMES <= SUBSTR(PHN.PHN_COMPET,4,4) || SUBSTR(PHN.PHN_COMPET,1,2))) " 
    cSql += "       AND PH6.D_E_L_E_T_ = ' ' " 
    cSql += "  ORDER BY PH5_CONTRA,PH5_REVISA,PH5_NUMERO,PH5_COMPET,PH5_CONDIC,PH5_CLIENT,PH5_LOJA,PH5_CONDPG,PH5_NOTASE,PH5_MOEDA,PH5_MASCCC,PH5_GU,PH5_SEQ "

Return cSql



Static Function GetItens(cCampo, aItens)
    Local np :=0
    Local uRet := NIL
    np := Ascan(aItens, {|x| x[1] == cCampo})
    If np > 0
        uRet := aItens[np, 2]
    EndIf 
Return uRet



Static Function VldCheck(oObjAux, cField, uNewConteu, nLine, uContOrig )
    Local cCompet   := oObjAux:GetValue('PH6_COMPET')

    If Empty(cCompet)
        Help(" ", 1, 'Help', 'TGCVA143', "Não existe competência pendente para gerar Pedido.", 3, 0)  
        Return .F.
    EndIf

Return .T.

Static Function VldMsg(oObjAux, cField, uNewConteu, nLine, uContOrig )
    Local cMsg    := uNewConteu 
    Local cUnineg := oObjAux:GetValue('PH6_UNINEG')
    Local nLimite := 0
    

    cMsg := LimpaMsg(cMsg)

    If ! LimiteMsg(cMsg, cUnineg, @nLimite)
        Help(" ", 1, 'Help', 'TGCVA143', "Para essa unidade " + cUnineg + ", a mensagem é limitada em " + Alltrim(Str(nLimite)) + " caracteres!", 3, 0) 
        cMsg := Left(cMsg, nLimite)
    EndIf 
    oObjAux:LoadValue(cField, cMsg)

Return .T.


User Function GC143LMSG(cMsg)

Return LimpaMsg(cMsg)

Static Function LimpaMsg(cMsgPed) 
    Local nx         := 0
    Local cChar      := ""
    Local cMsg       := ""
    Local cPermitido := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.,;:+-/=?!()$% "

    cMsgPed := Alltrim(cMsgPed)
    cMsgPed := NoAcento(cMsgPed)
    cMsg := ""
    For nx:= 1 to len(cMsgPed)
        cChar := subs(cMsgPed, nx, 1)
        If Asc(cChar) == 13
            cMsg += " "
        ElseIf Upper(cChar) $ cPermitido
            cMsg += cChar    
        EndIf 
    Next
    cMsg := StrTran(cMsg, "  ", " ")

Return cMsg

Static Function LimiteMsg(cMsg, cUnineg, nLimite)
    Local cLstUNeg := SuperGetMV("TI_LUNLIM",, "00001002700:150")  // Exemplo 00001002700:150;00001001200;100 
    Local aUnineg  := Separa(cLstUNeg,";")
    Local aAux     := {}
    Local cUniAux  := ""
    Local nLimAux  := 0
    Local nx 

    For nx := 1 to len(aUnineg)
        If Empty(aUnineg[nx])
            Loop 
        EndIf 
        aAux    := Separa(aUnineg[nx], ":")
        If len(aAux) < 2
            Loop 
        EndIf 
        cUniAux := aAux[1]
        nLimAux := Val(aAux[2])
        If cUniAux != cUnineg 
            Loop 
        EndIf 
        nLimite := nLimAux
        If len(cMsg) > nLimAux
           Return .f. 
        EndIf 
    Next 
    nLimite := 0

Return .T.

User Function GC143MSG(cMsg, cUnineg, nLimite)
        
    cMsg := LimpaMsg(cMsg)
    If ! LimiteMsg(cMsg, cUnineg, @nLimite)
        cMsg := Left(cMsg, nLimite)
    EndIf

Return cMsg


User Function GV143G02(cField, nFolder)

    Local oModel  := FWModelActive()
    Local oObjPH6 := oModel:GetModel("PH6MOD" + Str(nFolder, 1))
    Local oObjPH5 := oModel:GetModel("PH5MOD" + Str(nFolder, 1))
    Local nRecno  := 0
    Local lCheck  := oObjPH6:GetValue('PH6_CHECK')
    Local uRet    := NIL 
    Local nVlTPH6 := 0
    Local nQtdPH5 := 0 
    Local nVlUPH5 := 0
    Local nVlTPH5 := 0

    Local nVlrFat  := 0
    Local nVlrFatS := 0
    Local nVlrTrib := 0
    Local aAreaPH5 := PH5->(GetArea())
    Local nIndice  := 0
    Local nTotAnt  := 0

    Local cCondPg   := ""
    Local cParcelas := ""
    Local aParcelas := {}
    Local nTotal    := 0
    Local nx


    If cField == "PH6_CHECK2"
        uRet := lCheck 
    EndIf 

    If cField == "PH5_UNIFAT"
        nVlUPH5 := oObjPH5:GetValue('PH5_UNIFAT')
        nVlTPH5 := oObjPH5:GetValue('PH5_VLRFAT')
        nQtdPH5 := oObjPH5:GetValue('PH5_QTDFAT')

        nTotAnt := nVlUPH5 * nQtdPH5
        uRet    := nVlTPH5 / nQtdPH5 

        nVlTPH6 := oObjPH6:GetValue('PH6_VLRFAT')
        nVlTPH6 -= nTotAnt
        nVlTPH6 += nVlTPH5

        oObjPH6:LoadValue('PH6_VLRFAT', nVlTPH6)

        cCondPg   := oObjPH6:GetValue('PH6_CONDPG') 
        cParcelas := oObjPH6:GetValue('PH6_PARC') 
        aParcelas := {}
        nTotal    := 0
        
        SE4->(DbSetOrder(1))
        If ! SE4->(DbSeek(xFilial("SE4") + cCondPg))
            Help(" ", 1, 'Help', 'TGCVA143', "Condição de pagamento não cadastrada!", 3, 0)  
        EndIf 

        If SE4->E4_TIPO == "9"
            FWJsonDeserialize(cParcelas, @aParcelas)

            For nx:= 1 to len(aParcelas)
                nTotal += aParcelas[nx, 2]
            Next 
            
            If Round(nVlTPH6, 2) <> Round(nTotal, 2)
                If ! ManuParc(aParcelas, nVlTPH6)
                    aParcelas := {}
                    cParcelas := ""
                Else 
                    cParcelas := FwJsonSerialize(aParcelas)
                EndIf
                oObjPH6:LoadValue('PH6_PARC', cParcelas)
            EndIf 
        EndIf 
        
    EndIf 

    If cField == "PH5_VLFATS"
        nRecno  := oObjPH5:GetValue('PH5_RECNO')
        nVlTPH5 := oObjPH5:GetValue('PH5_VLRFAT')
        PH5->(DbGoto(nRecno))

        nVlrFat  := PH5->PH5_VLRFAT
        nVlrFatS := PH5->PH5_VLFATS
        nIndice  := nVlTPH5 / nVlrFat
        uRet     := nVlrFatS * nIndice
        
    EndIf 

    If cField == "PH5_VLTRIB"
        nRecno  := oObjPH5:GetValue('PH5_RECNO')
        nVlTPH5 := oObjPH5:GetValue('PH5_VLRFAT')
        PH5->(DbGoto(nRecno))

        nVlrFat  := PH5->PH5_VLRFAT
        nVlrTrib := PH5->PH5_VLTRIB

        nIndice  := nVlTPH5 / nVlrFat
        uRet     := nVlrTrib * nIndice
    EndIf 

    RestArea(aAreaPH5)

Return uRet



User Function GV143G03(oObjAux, cField, uNewConteu, nLine)
    Local nRecno   := oObjAux:GetValue('PH5_RECNO')
    Local nTolera  := SuperGetMv("TI_LALTPED",  , 1)
    Local aAreaPH5 := PH5->(GetArea())
    Local nVlrTot  := 0

    PH5->(DbGoto(nRecno))
    nVlrTot := PH5->PH5_VLRFAT
    RestArea(aAreaPH5)

    If uNewConteu < (nVlrTot - nTolera) 
        Help(" ", 1, 'Help', 'TGCVA143', I18N("Valor informado de R$ #1 menor que o limite de R$ #2 conforme tolerancia de R$ #3", {Alltrim(Str(uNewConteu, 12, 2)), Alltrim(Str(nVlrTot - nTolera, 12, 2)), AllTrim(Str(nTolera, 10, 2))}), 3, 0)  
        Return .F.
    ElseIf  uNewConteu > (nVlrTot + nTolera)
        Help(" ", 1, 'Help', 'TGCVA143', I18N("Valor informado de R$ #1 maior que o limite de R$ #2 conforme tolerancia de R$ #3", {Alltrim(Str(uNewConteu, 12, 2)), Alltrim(Str(nVlrTot + nTolera, 12, 2)), AllTrim(Str(nTolera, 10, 2))}), 3, 0)  
        Return .F.
    EndIf 


Return .t. 

User Function GV143G05(oObjAux, cField, uNewConteu, nLine)
    Local cCondPg   := uNewConteu
    Local cParcelas := oObjAux:GetValue('PH6_PARC') 
    Local nTotPed   := oObjAux:GetValue('PH6_VLRFAT') 
    Local aParcelas := {}
    Local nTotal    := 0
    Local nx
        
    If Empty(cCondPg)
        Return .t. 
    EndIf 
    SE4->(DbSetOrder(1))
    If ! SE4->(DbSeek(xFilial("SE4") + cCondPg))
        Help(" ", 1, 'Help', 'TGCVA143', "Condição de pagamento não cadastrada!", 3, 0)  
        Return .f. 
    EndIf 
    
    If SE4->E4_TIPO == "9"
        FWJsonDeserialize(cParcelas, @aParcelas)

        For nx:= 1 to len(aParcelas)
            nTotal += aParcelas[nx, 2]
        Next 

        If ! ManuParc(aParcelas, nTotPed)
            cParcelas := ""
            oObjAux:LoadValue('PH6_PARC', cParcelas)
            Return .f. 
        EndIf

        cParcelas := FwJsonSerialize(aParcelas)
    Else 
        cParcelas := ""
    EndIf 
    oObjAux:LoadValue('PH6_PARC', cParcelas)

Return .t. 

Static Function ManuParc(aParcelas, nTotPed)
    Local aHeader := {}
    Local aCols   := {}
        
    Local oModal 
    Local oDlg 
    Local oP1 
    Local oP2
    Local nQtdParc := 1
    Local oFontB   := TFont():New('Consolas',, 16,, .T.,,,,, .F., .F.)
    Local lOk      := .F.
    Local nx 
    Private nTotal   := 0
    Private oTotal 
    Private oGD  

    If Empty(aParcelas)
        aParcelas := {{ctod(""), 0}}
    EndIf 

    MtaHeader(aHeader)
	MtaCols(aHeader, aCols, aParcelas)

    oModal  := FWDialogModal():New()       
	oModal:SetEscClose(.T.)
    oModal:setTitle("Parcelas customizadas")
	oModal:setSize(260, 280)
    oModal:createDialog()
    oModal:addCloseButton({|| If(lOk:= VldOk(nTotPed), oModal:DeActivate(), .f. ) }, "OK")
    oModal:AddButton("Cancelar", {|| oModal:DeActivate() }     , "Cancelar",,.T.,.F.,.T.,)

    oDlg:= oModal:getPanelMain()
        
        oP1:= TPanelCss():New(,,, oDlg)
        oP1:SetCoors(TRect():New(0, 0, 95, 100))
        oP1:Align :=CONTROL_ALIGN_TOP

            @ 007, 002 SAY "Quantidade Parcelas" of oP1 SIZE 090, 10 PIXEL font oFontB
            @ 005, 090 GET nQtdParc              of oP1 SIZE 30, 09 PIXEL PICT "99"      VALID IncParc(nQtdParc) 

            @ 022, 002 SAY "Total Parcelas"     of oP1 SIZE 090, 10 PIXEL font oFontB
            @ 020, 090 MSGET oTotal Var nTotal   of oP1 SIZE 60, 09 PIXEL PICT "@e 999,999,999.99" WHEN .F.

            @ 037, 002 SAY "Total Pedido"       of oP1 SIZE 090, 10 PIXEL font oFontB
            @ 035, 090 GET nTotPed              of oP1 SIZE 60, 09 PIXEL PICT "@e 999,999,999.99" WHEN .F.

        oP2:= TPanelCss():New(,,, oDlg)
        oP2:SetCoors(TRect():New(0, 0, 38, 100))
        oP2:Align :=CONTROL_ALIGN_ALLCLIENT
        	oGD:= MsNewGetDados():New(000,000,000,000, 3  ,/*"U_TGC07LOk()"*/"AllWaysTrue()" ,"AllWaysTrue()", ,  ,,,"AllWaysTrue()",,, oP2 , aHeader , aCols )
			oGD:lInsert                := .F.
			oGD:oBrowse:Align          := CONTROL_ALIGN_ALLCLIENT
			oGD:bChange:= {|| U_GV143G08() }


    oModal:Activate()

    If lOk
        aParcelas:= {}
        For nx := 1 to len(oGD:aCols)
            aadd(aParcelas, {oGD:aCols[nx,2] , oGD:aCols[nx, 3]})
        Next
    Else 
        aParcelas:= {}
    EndIf 

Return lOk

Static Function VLDOK(nTotPed)
    Local aCols   := oGD:aCols
    Local nx      := 0 

    For nx:= 1 to len(aCols)
        dData := aCols[nx, 2]
        If Empty(dData)
            MsgAlert("Data não pode ser vazio")
            Return .f.
        EndIf 
        nValor := aCols[nx, 3]
        If Empty(nValor)
            MsgAlert("Valor não pode ser vazio")
            Return .f.
        EndIf 
    Next 

    If Round(nTotPed, 2) <> Round(nTotal, 2)
        MsgAlert("Total de parcelas diferente do total do pedido!")
        Return .f.
    EndIf 


Return .t. 
 

Static Function IncParc(nQtdParc) 
	Local aCols   := oGD:aCols
    Local nx      := 0

    If Empty(nQtdParc)
        Return .f. 
    EndIf 
    If nQtdParc > 36
        MsgStop("Total de parcelas não deve ser maior que 36!")
        Return .f. 
    EndIf 
    aCols := {}
    For nx := 1 to nQtdParc
        Aadd(aCols, {"Parcela " + Alltrim(Str(nx)), ctod(""), 0, "", .f. })
    Next 
	oGD:aCols   := aCols
	oGD:Refresh()
    
    nTotal :=0
    oTotal:Refresh()

Return 



Static Function MtaHeader(aHeader)
	Local nx 
	Local aEstru := {}
	
	Local cTitulo  := ""
	Local cCampo  := ""
	Local cPict    := ""
	Local nTam     := ""
	Local nDec     := ""
	Local cValid   := ""
	Local cUsado   := ""
	Local cTipo    := ""
	Local cF3      := ""
	Local cContext := ""
	Local cBox     := ""
	Local cRelacao := ""
	Local cWhen    := ""
	Local cVisual  := ""
	Local cVldUser := ""
	Local cPictVar := ""
	Local cObrigat := ""
	
	aHeader := {}
	
	aEstru := {"C5_DATA1","C5_PARC1"}
	AAdd(aHeader, {"Parcela", "TITULO", "@!", 11, 0, "", "", "C", "", "", "", "", "", "V", "", "", ""})
    For nx := 1 to len(aEstru)
		cCampo := aEstru[nx]

        If cCampo == "C5_DATA1"
            cTitulo  := "Vencimento"
            cValid   := "U_GV143G07(1)"
        ElseIf cCampo == "C5_PARC1"
            cTitulo  := "Valor"
            cValid   := "U_GV143G07(2)"
        Else 
            cTitulo  := Trim(FWGetSx3Cache(cCampo, "X3_TITULO" ))
        	cValid   := ".T." //FWGetSx3Cache(cCampo, "X3_VALID"  )
            
        EndIf 
		
		cPict    := FWGetSx3Cache(cCampo, "X3_PICTURE")
		nTam     := FWGetSx3Cache(cCampo, "X3_TAMANHO")
		nDec     := FWGetSx3Cache(cCampo, "X3_DECIMAL")
		cUsado   := FWGetSx3Cache(cCampo, "X3_USADO"  )
		cTipo    := FWGetSx3Cache(cCampo, "X3_TIPO"   )
		cF3      := FWGetSx3Cache(cCampo, "X3_F3"     )
		cContext := FWGetSx3Cache(cCampo, "X3_CONTEXT")
		cBox     := FWGetSx3Cache(cCampo, "X3_CBOX"   )
        cRelacao := FWGetSx3Cache(cCampo, "X3_RELACAO")
        cWhen    := FWGetSx3Cache(cCampo, "X3_WHEN"   )                           
		cVisual  := FWGetSx3Cache(cCampo, "X3_VISUAL" )
		cVldUser := ".T." //FWGetSx3Cache(cCampo, "X3_VLDUSER")                            
		cPictVar := FWGetSx3Cache(cCampo, "X3_PICTVAR")
		cObrigat := FWGetSx3Cache(cCampo, "X3_OBRIGAT")

		aAdd(aHeader,{cTitulo, cCampo , cPict, nTam, nDec, cValid, cUsado, cTipo, cF3, cContext, cBox, cRelacao, cWhen, cVisual, cVldUser, cPictVar, cObrigat})

	Next 
	AAdd(aHeader, {"", "NULO", "@!", 5, 0, "", "", "C", "", "", "", "", "", "V", "", "", ""})

Return 

Static Function MtaCols(aHeader, aCols, aParcelas)
	Local nx        := 0
	
    aCols   := {}

    For nx := 1 to len(aParcelas)
        Aadd(aCols, {"Parcela " + Alltrim(Str(nx)), aParcelas[nx, 1], aParcelas[nx, 2], "", .f. })
    Next 

Return 

User Function GV143G07(nTipo)
    Local dData 
    Local nValor 


    If nTipo == 1
        dData := M->C5_DATA1
        If Empty(dData)
            MsgAlert("Data não pode ser vazio")
            Return .f.
        EndIf 
        If dData < dDatabase
            MsgAlert("Data invalida!")
            Return .f.
        EndIf 

    Else 
        nValor := M->C5_PARC1
        If Empty(nValor)
            MsgAlert("Valor não pode ser vazio")
            Return .f.
        EndIf 
        If nValor < 0
            MsgAlert("Valor parcela não pode ser negativo!")
            Return .f.
        EndIf 
        U_GV143G08(nValor)


    EndIf 

Return .t. 


User Function GV143G08(nValor)
	Local aCols   := oGD:aCols
    Local nx      := 0
    nTotal := 0
    For nx := 1 to len(aCols)
        If nValor <> NIL .and. oGD:nAt == nx
            nTotal += nValor
        Else
            nTotal += aCols[nx, 3]
        EndIf 
    Next 
    oTotal:Refresh()
Return .t.


User Function GV143G09(oView)
    Local oDModal 
    Local oModel  := FWModelActive()
    Local oDlg 
    Local oFontB := TFont():New('Consolas',, 16,, .T.,,,,, .F., .F.)
    Local cMarca := "Sim"
    Local aMarca := {"Sim","Não"}
    Local oMarca
    Local cLibera := "Sim"
    Local aLibera := {"Sim","Não"}
    Local oLibera
    Local cReceita := "Todas"
    Local aReceita := {"Todas"}
    Local oReceita

    Local cComp := "Todas"
    Local aComp := {"Todas"}
    Local oComp

    Local cCliente := "Todos"
    Local aCliente := {"Todos"}
    Local oCliente 

    Local cUniFat := "Todas"
    Local aUniFat := {"Todas"}
    Local oUniFat 

    Local lOk      := .T.
    Local nFolder  :=  oView:GetFolderActive("PASTAS", 2)[1]
    Local oModPH6  := oModel:GetModel("PH6MOD" + Str(nFolder, 1))
    Local nx 

    Local cLRPH6   := ""
    Local cCmpPH6  := ""
    Local cCliPH6  := ""
    Local cUFPH6   := ""
   

    For nx := 1 To oModPH6:Length()
        oModPH6:GoLine(nx)
        
        If ! IsViewFilter(oView, oModPH6)
            Loop
        EndIf

        cLRPH6  := oModPH6:GetValue('PH6_LINREC')
        cCmpPH6 := oModPH6:GetValue('PH6_COMPET')
        cCliPH6 := oModPH6:GetValue('PH6_CLIENT')
        cUFPH6  := oModPH6:GetValue('PH6_UNINEG') + " " +  oModPH6:GetValue('PH6_UNIDES')

        If Empty(cUFPH6)
            Loop
        EndIf 

        If Ascan(aReceita, cLRPH6) == 0
            aadd(aReceita, cLRPH6)
        EndIf 

        If Ascan(aComp, cCmpPH6) == 0
            aadd(aComp, cCmpPH6)
        EndIf 

        If Ascan(aCliente, cCliPH6) == 0
            aadd(aCliente, cCliPH6)
        EndIf 

        If Ascan(aUniFat, cUFPH6) == 0
            aadd(aUniFat, cUFPH6)
        EndIf 

    Next 

	
    oDModal  := FWDialogModal():New()       
	oDModal:SetEscClose(.T.)
    oDModal:setTitle("Seleção em lote")
	oDModal:setSize(160, 200)
    oDModal:createDialog()
    oDModal:addCloseButton({|| oDModal:DeActivate() }, "OK")
    oDModal:AddButton("Cancelar", {|| lOk:= .F., oDModal:DeActivate() }     , "Cancelar",,.T.,.F.,.T.,)

    oDlg:= oDModal:getPanelMain()
    

        @ 007, 002 SAY "Marca"            of oDlg SIZE 070, 10 PIXEL font oFontB
        @ 005, 072 MSCOMBOBOX oMarca     VAR cMarca    ITEMS aMarca   SIZE 40, 09 PIXEL OF oDlg 

        @ 022, 002 SAY "Liberado"         of oDlg SIZE 070, 10 PIXEL font oFontB
        @ 020, 072 MSCOMBOBOX oLibera    VAR cLibera    ITEMS aLibera   SIZE 40, 09 PIXEL OF oDlg 

        @ 037, 002 SAY "Linha de Receita" of oDlg SIZE 070, 10 PIXEL font oFontB
        @ 035, 072 MSCOMBOBOX oReceita   VAR cReceita   ITEMS aReceita   SIZE 120, 09 PIXEL OF oDlg 
      
        @ 052, 002 SAY "Competencia" of oDlg SIZE 070, 10 PIXEL font oFontB
        @ 050, 072 MSCOMBOBOX oComp      VAR cComp   ITEMS aComp   SIZE 120, 09 PIXEL OF oDlg 

        @ 067, 002 SAY "Cliente"      of oDlg SIZE 070, 10 PIXEL font oFontB
        @ 065, 072 MSCOMBOBOX oCliente    VAR cCliente   ITEMS aCliente  SIZE 120, 09 PIXEL OF oDlg 

        @ 082, 002 SAY "Unidade Faturamento"      of oDlg SIZE 070, 10 PIXEL font oFontB
        @ 080, 072 MSCOMBOBOX oUniFat    VAR cUniFat   ITEMS aUniFat  SIZE 120, 09 PIXEL OF oDlg 


    oDModal:Activate()

    If lOk 
        For nx := 1 To oModPH6:Length()
            oModPH6:GoLine(nx)

            If ! IsViewFilter(oView, oModPH6)
                Loop
            EndIf 

            
            lCheck  := oModPH6:GetValue('PH6_CHECK')
            lCheck2 := oModPH6:GetValue('PH6_CHECK2')
            cLRPH6  := oModPH6:GetValue('PH6_LINREC')
            cCmpPH6 := oModPH6:GetValue('PH6_COMPET')
            cCliPH6 := oModPH6:GetValue('PH6_CLIENT')
            cUFPH6  := oModPH6:GetValue('PH6_UNINEG') + " " +  oModPH6:GetValue('PH6_UNIDES')

            If Empty(cLRPH6)
                Loop
            EndIf 
            If Alltrim(cReceita) <> "Todas" .and. Alltrim(cReceita) <> Alltrim(cLRPH6)
                Loop 
            EndIf 
            
            If Alltrim(cComp) <> "Todas" .and. Alltrim(cComp) <> Alltrim(cCmpPH6)
                Loop 
            EndIf 
            If Alltrim(cCliente) <> "Todos" .and. Alltrim(cCliente) <> Alltrim(cCliPH6)
                Loop 
            EndIf 

            If Alltrim(cUniFat) <> "Todas" .and. Alltrim(cUniFat) <> Alltrim(cUFPH6)
                Loop 
            EndIf 

            oModPH6:LoadValue("PH6_CHECK" , cMarca == "Sim")
            If cMarca == "Não"
                cLibera := "Não"
            EndIf 
            
            oModPH6:LoadValue("PH6_CHECK2", cLibera == "Sim")
        Next 
        oModPH6:GoLine(1)    

    EndIf 
    
Return .t.

Static Function IsViewFilter(oView, oModPH6)
    Local nFolder   := oView:GetFolderActive("PASTAS", 2)[1]
    Local oSubView  := oView:GetSubView("PH6MOD" + Str(nFolder, 1))
    Local aFields   := oSubView:aFieldID
    Local oFWFilter := oSubView:oBrowse:FWFilter()
    Local nx        := 0
    Local lAtivo    := .F.
    Local cFiltro   := ""
    
    aFilter :=oFWFilter:aFilter
   
    For nx := 1 to len(aFilter)
        lAtivo := aFilter[nx, 6]
        If ! lAtivo
            Loop
        EndIf 
        cFiltro := aFilter[nx, 2]
        cFiltro := TrataFiltro(cFiltro, aFields)
        If ! &cFiltro// &cFiltro
            Return .F. 
        EndIf  

    Next 

Return .T. 

Static Function TrataFiltro(cFiltro, aFields)
    Local nx := 0

    For nx:= 1 to len(aFields)
	    cFiltro := StrTran(cFiltro, aFields[nx], "oModPH6:GetValue('" + aFields[nx] + "')")  	
    Next

Return cFiltro


