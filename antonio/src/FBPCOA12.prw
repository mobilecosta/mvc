#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
Static __aZZ6   := {}
Static __aZZ62   := {}


User Function FBPCOA12()
	Local oBrowse
	Local aArea	:= GetArea()
    Private oClone := Nil

	DbSelectArea("ZZ5")

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('ZZ5')
	oBrowse:SetDescription("SOLICITAÇÃO DE RECURSOS")
	
    oBrowse:AddLegend( "ZZ5_STATUS=='1'", "WHITE", "Pendente de Aprovação Gestor (Nível 1)"  ) // Exclui - Altera 
    oBrowse:AddLegend( "ZZ5_STATUS=='2'", "BLACK", "Pendente de Aprovação Gestor (Nível 2)"  ) // Exclui - Altera
    oBrowse:AddLegend( "ZZ5_STATUS=='3'", "YELLOW","Pendente de Aprovação Controladoria (Faixa de Valor / Grupo de Contas)"  ) // Exclui - Altera
    oBrowse:AddLegend( "ZZ5_STATUS=='4'", "BLUE" , "Pendente de Aprovação Controladoria (Grupo de Contas)"  ) // Exclui - Altera

    oBrowse:AddLegend( "ZZ5_STATUS=='5'", "PINK", "Pendente Controladoria"  )
    oBrowse:AddLegend( "ZZ5_STATUS=='6'", "RED","Solicitação Rejeitada"  )
    oBrowse:AddLegend( "ZZ5_STATUS=='7'", "GREEN" , "Solicitação Aprovada"  )

    oBrowse:DisableDetails()
	oBrowse:Activate()

	RestArea(aArea)

Return NIL


//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina := {}

     ADD OPTION aRotina TITLE 'Incluir Origem'          ACTION 'VIEWDEF.TINCA001' OPERATION MODEL_OPERATION_INSERT   ACCESS 0 //OPERATION 1
    ADD OPTION aRotina TITLE 'Incluir Destino'         ACTION 'VIEWDEF.FBPCOA12' OPERATION MODEL_OPERATION_INSERT   ACCESS 0 //OPERATION 1

    //ADD OPTION aRotina TITLE "Pesquisar"	   ACTION "PesqBrw"          OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Visualizar" 	   ACTION "VIEWDEF.TINCA001" OPERATION 2 ACCESS 0
    //ADD OPTION aRotina TITLE "Incluir"    	   ACTION "VIEWDEF.TINCA001" OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE 'Excluir'         ACTION 'VIEWDEF.TINCA001' OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5
    ADD OPTION aRotina TITLE 'Aprovação'       ACTION 'u_AprovPCO()' OPERATION MODEL_OPERATION_INSERT  ACCESS 0 //OPERATION 1
  
Return aRotina


//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
Static Function ModelDef()
	Local oStruZZ5 := FWFormStruct( 1, 'ZZ5' )
	Local oStruZZ62 := FWFormStruct( 1, 'ZZ6' )
    Local oStruZZ6 := FWFormStruct( 1, 'ZZ6' )
    // MPFORMMODEL():New(< cID >, < bPre >, < bPost >, < bCommit >, < bCancel >)-> NIL
	Local oModel   := MPFormModel():New('xFBPCOA12', { |oModel|GatZZ6()}, /*{ |oModel| TINCA01POS(oModel)}*/, { |oModel| TINCA01GRV(oModel)})
    
	/*
 aAux := {} 
 aAux := FWStruTrigger('ZZ5_DOC','ZZ6_DOC','GatZZ6(M->ZZ5_DOC)',.F.) 
 oStruZA4:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4]) 
 */
 // //oStruct:AddTrigger("Campo Origem", "Campo Destino", "Bloco de código na validação da execução do gatilho", "Bloco de código na execução do gatilho")

	oModel:AddFields( 'ZZ5MASTER',, oStruZZ5)
	oModel:SetDescription("SOLICITAÇÃO DE RECURSOS - ORIGEM-debito")
	oModel:SetPrimaryKey( {} )
/*
	oModel:AddGrid('ZZ6DETAIL', 'ZZ5MASTER', oStruZZ6,;
                { |oModelZZ6, nLine ,cAction,cField| VldGrid6(oModelZZ6, nLine, cAction, cField) })

	oModel:AddGrid('ZZ62DETAIL', 'ZZ6DETAIL', oStruZZ62,;
                { |oModelZZ62, nLine ,cAction,cField| VldGrid62(oModelZZ62, nLine, cAction, cField) })
*/

//    oModel:AddGrid('ZZ6DETAIL','ZZ5MASTER', oStruZZ6 ,,,,, {|oGrid| LeCab(oGrid, 1)}         )
//    oModel:AddGrid('ZZ62DETAIL','ZZ6DETAIL'  , oStruZZ62 ,,,,, {|oGrid| LeItens(oGrid, oModel, 1 )})

    oModel:AddGrid('ZZ62DETAIL','ZZ5MASTER', oStruZZ62)
    oModel:AddGrid('ZZ6DETAIL','ZZ5MASTER'  , oStruZZ6)


	//oModel:GetModel('ZZ6DETAIL'):SetUniqueLine({"ZZ6_DOC"})
    //oModel:GetModel('ZZ62DETAIL'):SetUniqueLine({"ZZ6_DOC"})

    oModel:SetRelation('ZZ62DETAIL', { { 'ZZ6_FILIAL', 'xFilial("ZZ6")' },;
									  { 'ZZ6_DOC', 'ZZ5_DOC'  } ,; 
                                      { 'ZZ6_TIPO', "'C'"  } },; 
		                              ZZ6->(IndexKey(3)) )

	oModel:SetRelation('ZZ6DETAIL', { { 'ZZ6_FILIAL', 'xFilial("ZZ6")' },;
									  { 'ZZ6_DOC', 'ZZ5_DOC'  } ,; 
                                      { 'ZZ6_TIPO', "'D'"  } },; 
		                              ZZ6->(IndexKey(3)) )

    oModel:GetModel('ZZ6DETAIL'):SetMaxLine( 1 )
    oModel:GetModel('ZZ5MASTER'):SetDescription("SOLICITAÇÃO DE RECURSOS")
	oModel:GetModel('ZZ62DETAIL'):SetDescription("ORIGEM DOS RECURSOS-debito")
    oModel:GetModel('ZZ6DETAIL'):SetDescription("DESTINO DOS RECURSOS-credito")
 //   oModel:InstallEvent("TINCA001EV", /*cOwner*/, oCommit)

 Return oModel


//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
Static Function ViewDef()

	Local oModel  := FWLoadModel("FBPCOA12")
    Local oStruZZ5 := FWFormStruct(2, 'ZZ5')
    Local oStruZZ62 := FWFormStruct(2, 'ZZ6')
    Local oStruZZ6 := FWFormStruct(2, 'ZZ6')
	Local oView

   // oStruZZ6:RemoveField('ZZ6_IDPROC')
    oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_ZZ5', oStruZZ5, 'ZZ5MASTER')

	oView:CreateHorizontalBox('SUPERIOR', 15)
	oView:CreateHorizontalBox('INFERIOR', 60)
	oView:CreateHorizontalBox('BAIXO', 25)

	OView:SetOwnerView('VIEW_ZZ5', 'SUPERIOR')

	oView:AddGrid('VIEW_ZZ62', oStruZZ62, 'ZZ62DETAIL')
oStruZZ6:RemoveField('ZZ6_DOC')
oStruZZ6:RemoveField('ZZ6_TIPO')
	OView:SetOwnerView('VIEW_ZZ62', 'INFERIOR')
	OView:EnableTitleView('VIEW_ZZ62', 'DESTINO DOS RECURSOS-credito')

	oView:AddGrid('VIEW_ZZ6', oStruZZ6, 'ZZ6DETAIL')
    OView:SetOwnerView('VIEW_ZZ6', 'BAIXO')
	OView:EnableTitleView('VIEW_ZZ6', 'ORIGEM DOS RECURSOS-debito')
oStruZZ62:RemoveField('ZZ6_DOC')
oStruZZ62:RemoveField('ZZ6_TIPO')
	//oView:SetViewCanActivate({|oView| VldView(oView)})
    
	//oView:AddUserButton( 'Registros Incorporação', 'CLIPS', {|oView| U_TINCMON(oView)} )

Return oView

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
Static Function VldView(oView)

    Local oModel	:= oView:GetModel()
    Local nOpc	    := oModel:GetOperation()
    Local oMdlPHG	:= oModel:GetModel("ZZ62DETAIL")
    Local lSemEdit  := .F.

    // Não permite edição caso já iniciou a simulação/execução
    If nOpc <> MODEL_OPERATION_INSERT
        ZZ6->(DbSeek(xFilial("ZZ6") + ZZ5->ZZ5_IDPROC))
        While ZZ6->ZZ6_FILIAL == xFilial("ZZ6") .And. ZZ6->ZZ6_DOC == ZZ5->ZZ5_DOC .And.;
            ! ZZ6->(Eof())
           If ZZ6->ZZ6_TIPO == "C"
                lSemEdit := .T.
            EndIF
            ZZ6->(DbSkip())
        EndDo
    EndIf
    
    oMdlPHG:SetNoInsertLine(lSemEdit)
    oMdlPHG:SetNoUpdateLine(lSemEdit)
    oMdlPHG:SetNoDeleteLine(lSemEdit)

Return .T.

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
Static Function VldGrid6(oModelZZ6, nLine, cAction, cField)

Local lRet := .T.
Local cMsg := ""
 
 
nOperation := oModelZZ6:GetOperation() 

If  (nOperation == MODEL_OPERATION_INSERT) 
   If nLine > 1
       oModelZZ62 := oClone  
        oModelZZ62:GetValue("ZZ6_TIPO") := "C"
        oModelZZ62:GetValue("ZZ6_FILIAL") := oModelZZ6:GetValue("ZZ6_FILIAL")
        oModelZZ62:GetValue("ZZ6_DOC") := oModelZZ6:GetValue("ZZ6_DOC")
        oModelZZ62:GetValue("ZZ6_DATA") := oModelZZ6:GetValue("ZZ6_DATA")
        oModelZZ62:GetValue("ZZ6_CO") := oModelZZ6:GetValue("ZZ6_CO")
        oModelZZ62:GetValue("ZZ6_CLASSE") := oModelZZ6:GetValue("ZZ6_CLASSE")
        oModelZZ62:GetValue("ZZ6_CC") := oModelZZ6:GetValue("ZZ6_CC")
        
        oModelZZ62:GetValue("ZZ6_FILIAL") := oModelZZ62:ADATAMODEL[1][1][1][1]
        oModelZZ62:GetValue("ZZ6_DOC") := oModelZZ62:ADATAMODEL[1][1][1][2]
        oModelZZ62:GetValue("ZZ6_TIPO") := oModelZZ62:ADATAMODEL[1][1][1][3]
        oModelZZ62:GetValue("ZZ6_DATA") := oModelZZ62:ADATAMODEL[1][1][1][4]
        oModelZZ62:GetValue("ZZ6_CO") := oModelZZ62:ADATAMODEL[1][1][1][5]
        oModelZZ62:GetValue("ZZ6_CLASSE") := oModelZZ62:ADATAMODEL[1][1][1][6]
    EndIf
    
EndIf

If  (cAction == "DELETE") //;.Or. cAction == "CANSETVALUE") .And.;
    //(oModelGrid:GetValue("ZZ6_TIPO") == "C")
    lRet := .F.
    If cAction == "DELETE"
        cMsg := "Carga de Registros já realizada"
        If oModelZZ6:GetValue("ZZ6_TIPO") == "D"
            cMsg := "Tipo DEBITO não pode ser excluído"
        EndIF
        cMsg := "Documento: " + oModelZZ6:GetValue("ZZ6_DOC") + "-" + cMsg + " !"
        Help(,, "PCO JA INSERIDO",, cMsg, 1, 0) 
    EndIf
EndIf

Return lRet


Static Function VldGrid62(oModelZZ62, nLine, cAction, cField)
Local lRet := .T.
Local aAreaZZ62 := GetArea("ZZ6")
Local aCopiaZZ62 := {}

nOperation := oModelZZ62:GetOperation() 

If  (nOperation == MODEL_OPERATION_INSERT) 
    If nLine > 1
        oModelZZ62:GetValue("ZZ6_FILIAL") := oClone:GetValue("ZZ5_FILIAL")
        oModelZZ62:GetValue("ZZ6_DOC") := oClone:GetValue("ZZ5_DOC")
        oModelZZ62:GetValue("ZZ6_DATA") := oClone:GetValue("ZZ6_DATA")
        oModelZZ62:GetValue("ZZ6_CO") := oClone:GetValue("ZZ6_CO")
        oModelZZ62:GetValue("ZZ6_CLASSE") := oClone:GetValue("ZZ6_CLASSE")
        oModelZZ62:GetValue("ZZ6_CC") := oClone:GetValue("ZZ6_CC")

    Else
        oModelZZ62:GetValue("ZZ6_TIPO") := "C"
        
        oModelZZ62:GetValue("ZZ6_FILIAL") := oModelZZ62:ADATAMODEL[1][1][1][1]
        oModelZZ62:GetValue("ZZ6_DOC") := oModelZZ62:ADATAMODEL[1][1][1][2]
        oModelZZ62:GetValue("ZZ6_TIPO") := oModelZZ62:ADATAMODEL[1][1][1][3]
        oModelZZ62:GetValue("ZZ6_DATA") := oModelZZ62:ADATAMODEL[1][1][1][4]
        oModelZZ62:GetValue("ZZ6_CO") := oModelZZ62:ADATAMODEL[1][1][1][5]
        oModelZZ62:GetValue("ZZ6_CLASSE") := oModelZZ62:ADATAMODEL[1][1][1][6]
    EndIf
    oClone := oModelZZ62

EndIf

RestArea(aAreaZZ62)
Return .T.




//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
Static Function TINCA01POS(oModel)
	Local cError	 := ""
    Local nOperation := 0
    Local cFilOri    := ""
    Local cFilDes    := ""
    Local nPos       := 0
    Local oZZ62
    Local oZZ5
    Local cRet      := ""
    Local cID       := ""
    Local cIDDescr  := ""

	If oModel == Nil
		Return .F.
	EndIf

	nOperation := oModel:GetOperation()

    oZZ5 := oModel:GetModel('ZZ5MASTER')

    cFilOri    := oZZ5:GetValue('ZZ5_FILIAL')
    cID        := oZZ5:GetValue('ZZ5_DOC')
    cIDDescr   := oZZ5:GetValue('ZZ5_USER')
    
    oZZ62 := oModel:GetModel('ZZ62DETAIL')
    For nPos := 1 To oZZ62:Length()
        oZZ62:GoLine(nPos)
 /*       If nOperation == MODEL_OPERATION_DELETE
            If oZZ6:GetValue("ZZ6_STEXEC") <> "1"
                cError := "A rotina [" + oZZ6:GetValue("ZZ6_CODROT") + "] já teve o status de execução iniciado. Processo não pode ser excluido !"
                Exit
            EndIF
        Else
            If ! FindFunction(oZZ6:GetValue("ZZ6_FUNLOG"))
                cError := "A função [" + oZZ6:GetValue("ZZ6_FUNLOG") + "] informada para rotina [" + oZZ6:GetValue("ZZ6_CODROT") + "] não está compilada no repositorio !"
                Exit
            EndIF

            If ! FindFunction(oZZ6:GetValue("ZZ6_FUNPRO"))
                cError := "A função [" + oZZ6:GetValue("ZZ6_FUNPRO") + "] informada para rotina [" + oZZ6:GetValue("ZZ6_CODROT") + "] não está compilada no repositorio !"
                Exit
            EndIF
        EndIf
    */Next

Return Empty(cError)

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
Static Function TINCA01GRV(oModel)
    Local nPos   := 0
    Local nModel := 0
    Local oZZ62
    Local oZZ5

	If oModel == Nil
		Return .F.
	EndIf

    oZZ5 := oModel:GetModel('ZZ5MASTER')

    ZZ5->(RecLock("ZZ5", .T.))
    ZZ5->ZZ5_FILIAL := xFilial('ZZ5')
    ZZ5->ZZ5_DOC    := oZZ5:GetValue('ZZ5_DOC')
    ZZ5->ZZ5_USER   := oZZ5:GetValue('ZZ5_USER')
    ZZ5->ZZ5_NUSER	:= oZZ5:GetValue('ZZ5_NUSER')
    ZZ5->ZZ5_DATA 	:= oZZ5:GetValue('ZZ5_DATA')
    ZZ5->ZZ5_HORA 	:= oZZ5:GetValue('ZZ5_HORA')  
    ZZ5->(MsUnlock())

    For nModel := 1 To 2
        oZZ62 := oModel:GetModel('ZZ62DETAIL')
        If nModel == 2
            oZZ62 := oModel:GetModel('ZZ6DETAIL')
            //ZZ6->(RecLock("ZZ6", .F.))
        //Else    
            //ZZ6->(RecLock("ZZ6", .T.))
        EndIf
        For nPos := 1 To oZZ62:Length()
            oZZ62:GoLine(nPos)
            ZZ6->(RecLock("ZZ6", .T.))
            ZZ6->ZZ6_FILIAL := xFilial('ZZ6')
            ZZ6->ZZ6_DOC    := oZZ5:GetValue('ZZ5_DOC')
            ZZ6->ZZ6_TIPO   := iIf(nModel==2,"D","C") //oZZ6:GetValue('ZZ6_TIPO')
            ZZ6->ZZ6_DATA   := oZZ62:GetValue('ZZ6_DATA')
            ZZ6->ZZ6_CLASSE := oZZ62:GetValue('ZZ6_CLASSE')
            ZZ6->ZZ6_CO		:= oZZ62:GetValue('ZZ6_CO')
            ZZ6->(MsUnlock())
        Next
    Next

Return .T.

Static Function GatZZ6(OmODEL)
Local lRet := .T.
Local oModel := FWModelActive()
Local cDesc := oModel:GetValue('ZZ5MASTER','ZZ5_DOC')


	Local cError	 := ""
    Local nOperation := 0
    Local cFilOri    := ""
    Local cFilDes    := ""
    Local nPos       := 0
    Local oZZ6
    Local oZZ5
    Local cRet      := ""
    Local cID       := ""
    Local cIDDescr  := ""

	If oModel == Nil
		Return .F.
	EndIf

	nOperation := oModel:GetOperation()

    oZZ5 := oModel:GetModel('ZZ5MASTER')

    cFilOri    := oZZ5:GetValue('ZZ5_FILIAL')
    cID        := oZZ5:GetValue('ZZ5_DOC')
    cIDDescr   := oZZ5:GetValue('ZZ5_USER')
        cdATA   := oZZ5:GetValue('ZZ5_DATA')
    oZZ6 := oModel:GetModel('ZZ6DETAIL')
 /*   For nPos := 1 To oZZ6:Length()
        oZZ6:GoLine(nPos)
        If nOperation == MODEL_OPERATION_INSERT
            oModel:SetValue('ZZ6DETAIL','ZZ6_DOC',cDesc)
            //oModel:SetValue('ZZ62DETAIL','ZZ6_DOC',cDesc)
            //oModel:SetValue('ZZ62DETAIL','ZZ6_DATA',cdATA)
        EndIf
 /*       If nOperation == MODEL_OPERATION_DELETE
            If oZZ6:GetValue("ZZ6_STEXEC") <> "1"
                cError := "A rotina [" + oZZ6:GetValue("ZZ6_CODROT") + "] já teve o status de execução iniciado. Processo não pode ser excluido !"
                Exit
            EndIF
        Else
            If ! FindFunction(oZZ6:GetValue("ZZ6_FUNLOG"))
                cError := "A função [" + oZZ6:GetValue("ZZ6_FUNLOG") + "] informada para rotina [" + oZZ6:GetValue("ZZ6_CODROT") + "] não está compilada no repositorio !"
                Exit
            EndIF

            If ! FindFunction(oZZ6:GetValue("ZZ6_FUNPRO"))
                cError := "A função [" + oZZ6:GetValue("ZZ6_FUNPRO") + "] informada para rotina [" + oZZ6:GetValue("ZZ6_CODROT") + "] não está compilada no repositorio !"
                Exit
            EndIF
        EndIf
    Next
*/
 /*   If ! Empty(cError)
        Help(,, "Incorporador",, cError, 1, 0) 
    Else
        cRet := SendToken(cID,__cUserID,cFilOri,cFilDes,cIDDescr) 
        If empty(cRet)   
            Help(,, "Incorporador",, "Problemas no envio de email com o Token.", 1, 0) 
        Endif
    EndIf
*/



//MPFORMMODEL():AddGrid(< cId >, < cOwner >, < oModelStruct >, < bLinePre >, < bLinePost >, < bPre >, < bPost >, < bLoad
Return lRet



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

    __aZZ6    := {}
    __aZZ62    := {}

    If nFolder == 1
        aZZ6      := aClone(__aZZ6)
    ElseIf nFolder == 2
        aZZ62      := aClone(__aZZ62)
    EndIf 

    For nx := 1 to len(aZZ6) 
        
        aAux := {}
        For nc := 1 to len(aCmpGrid)
            cCampo    := aCmpGrid[nC, 3]

            uConteudo := GetItens(cCampo, aZZ6[nx])
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
    Local oObjCrn   := oModel:GetModel('ZZ6DETAIL' + Str(nFolder, 1))
    
    Local cCampo    := ""
    Local uConteudo := NIL 
    Local nx        := 0
    Local nc        := 0
    Local aPH5      := {}

    Local nPosZZ6   := oObjCrn:GetValue('ZZ6_DOC')
    Local nPosUlt   := 0

    If nFolder == 1 
        If nPosZZ6 > 0
            nPosUlt := len(__aZZ6[nPosZZ6])
            aZZ5    := aClone(__aZZ6[nPosZZ6, nPosUlt, 2])
        EndIf 
    ElseIf nFolder == 2 
        If nZZ6 > 0
            nPosUlt := len(__aZZ62[nPosZZ6])
            aZZ5    := aClone(__aZZ62[nPosZZ6, nPosUlt, 2])
        EndIf
    EndIf 

    For nx := 1 to len(aZZ5)
        aAux := {}
        For nc := 1 to len(aCmpGrid)
            cCampo    := aCmpGrid[nC, 3]
            uConteudo := GetItens(cCampo, aZZ5[nx])
            aadd(aAux, uConteudo)
        Next 
        aAdd(aRet,{0 , aClone(aAux)})
    Next 

Return aRet


User Function AprovPCO()
Local aParamBox	:= {}
Local cTitulo := "Parâmetros"
Local cDataDe :=  dDataBase
Local cDataAt :=  dDataBase
Local cAlias := "ZZ6"
Local lRet   := .T.
Local lRetorno := .F.
Local cQuery := ""
Local cTmpZZ6 := GetNextAlias()

//Local cUser :=  FwFldGet("ZZ6_USER")    
//Local cFil :=  FwFldGet("ZZ6_FILIAL")
//Local cDoc :=  FwFldGet("ZZ6_DOC")
Local aRet		:= {}
Local aAux		:= {}

(cAlias)->(dbSelectArea(cAlias))
(cAlias)->(dbSetOrder(1))

AADD(aParamBox,{1,"Data De"	, cDataDe	, "99/99/9999", "NaoVazio()",,, 60, .T.})
AADD(aParamBox,{1,"Data Ate", cDataAt	, "99/99/9999", "NaoVazio()",,, 60, .T.})

If !ParamBox(aParamBox, cTitulo, @aRet,,,,,,,, .F.) 
	Return( .F. )
EndIf

         //u_ValidaCal(FwFldGet("ZZ6_DATA") , lRetorno )
       //cData := DtoS(FwFldGet("ZZ6_DATA"))
        cQuery := " SELECT ZZ6.ZZ6_FILIAL, ZZ6.ZZ6_DATA, ZZ5.ZZ5_DATA, ZZ5.ZZ5_USER, ZZ5.ZZ5_STATUS "
        cQuery += " FROM " + RetSQLName("ZZ6") + " ZZ6, " +  RetSQLName("ZZ5") + " ZZ5 " 
        cQuery += " WHERE ZZ5.D_E_L_E_T_ = ' ' AND ZZ6.D_E_L_E_T_ = ' ' "  
        cQuery += " AND ZZ5.ZZ5_FILIAL = '" + xFilial("ZZ5") + "' "
        cQuery += " AND ZZ5.ZZ5_FILIAL = ZZ6.ZZ6_FILIAL "
        cQuery += " AND ZZ6.ZZ6_DATA BETWEEN '" + DtoS(cDataDe) + "' AND '" + DtoS(cDataAt) + "' "
        cQuery += " AND ZZ5.ZZ5_STATUS IN (1,2,4) "  
//        cQuery += " AND ZZ4.ZZ4_STATUS = 'A' "
        
        cQuery := ChangeQuery(cQuery)
    
        If Select(cTmpZZ6) > 0
            DbSelectArea(cTmpZZ6)
            (cTmpZZ6)->(DbCloseArea())
        EndIf				
                        
        dbUseArea(.T., "TOPCONN", TcGenQry(,,cQuery), cTmpZZ6, .T., .F.)
                                    
        If !(cTmpZZ6)->(Eof())


           
            return


        EndIf


Return
