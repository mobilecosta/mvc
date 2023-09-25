#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

User Function TINCA001()
	Local oBrowse
	Local aArea	:= GetArea()
    Private oClone := Nil

	DbSelectArea("ZZ5")

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('ZZ5')
	oBrowse:SetDescription("SOLICITAÇÃO DE RECURSOS - DESTINO")
	oBrowse:DisableDetails()
	oBrowse:Activate()

	RestArea(aArea)

Return NIL


//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina := {}

    ADD OPTION aRotina TITLE "Pesquisar"	        ACTION "PesqBrw"             	OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Visualizar" 	        ACTION "VIEWDEF.TINCA001" 		OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE "Incluir"    	        ACTION "VIEWDEF.TINCA001" 		OPERATION 3 ACCESS 0


Return aRotina


//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
Static Function ModelDef()
	Local oStruZZ5 := FWFormStruct( 1, 'ZZ5' )
	Local oStruZZ6 := FWFormStruct( 1, 'ZZ6' )
    Local oStruZZ62 := FWFormStruct( 1, 'ZZ6' )
    // MPFORMMODEL():New(< cID >, < bPre >, < bPost >, < bCommit >, < bCancel >)-> NIL
	Local oModel   := MPFormModel():New('TINCM001',/* { |oModel|GatZZ6()}*/,{ |oModel| TINCA01POS(oModel)}, { |oModel| TINCA01GRV(oModel)})
    Local bLinePos := {|oMdl| u_zz6bLinP(oModel)}
 
    bBloc:=FWBuildFeature(STRUCT_FEATURE_VALID,"'U_ZZ6ItC()', .T.")


    oStruZZ5:SetProperty('ZZ5_DOC', MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, '.F.')) //Modo de Edição
    //oStruZZ5:SetProperty('ZZ5_DOC', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'IiF(INCLUI,GETSXENUM("ZZ5","ZZ5_DOC"),"ZZ5_DOC")')) //Modo de Edição
   
    oStruZZ5:SetProperty('ZZ5_STATUS', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, '"1"')) //Inicializador Padrão
    //oStruZZ5:SetProperty('ZZ5_STATUS', MODEL_FIELD_WHEN, FwBuildFeature(MODEL_FIELD_WHEN, '.F.')) //Inicializador Padrão
    oStruZZ5:SetProperty('ZZ5_USER', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'RetCodUsr()')) //Inicializador Padrão
    //oStruZZ5:SetProperty('ZZ5_USER', MODEL_FIELD_WHEN, FwBuildFeature(MODEL_FIELD_WHEN, '.F.')) //Inicializador Padrão
    //oStruZZ5:SetProperty('ZZ5_NUSER', MODEL_FIELD_WHEN, FwBuildFeature(MODEL_FIELD_WHEN, '.F.')) //Inicializador Padrão
    oStruZZ5:SetProperty('ZZ5_NUSER', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'UsrFullName(RetCodUsr())')) //Inicializador Padrão
    //oStruZZ5:SetProperty('ZZ5_DATA', MODEL_FIELD_WHEN, FwBuildFeature(MODEL_FIELD_WHEN, '.F.')) //Inicializador Padrão
    oStruZZ5:SetProperty('ZZ5_DATA', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'Date()')) //Inicializador Padrão
    //oStruZZ5:SetProperty('ZZ5_HORA', MODEL_FIELD_WHEN, FwBuildFeature(MODEL_FIELD_WHEN, '.F.')) //Inicializador Padrão
    oStruZZ5:SetProperty('ZZ5_HORA', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'Time()')) //Inicializador Padrão
    
    oStruZZ6:SetProperty('ZZ6_DATA', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'Date()')) //Inicializador Padrão
    oStruZZ62:SetProperty('ZZ6_DATA', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'Date()')) //Inicializador Padrão

    oStruZZ6:SetProperty("ZZ6_ITCTA", MODEL_FIELD_VALID,bBloc ) 
    oStruZZ62:SetProperty("ZZ6_ITCTA", MODEL_FIELD_VALID,bBloc ) 
    //oStruZZ62:SetProperty('ZZ6_ITCTA', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'U_ZZ6ItC()')) //Inicializador Padrão
//ZZ6ITC
    oModel:AddFields( 'ZZ5MASTER',, oStruZZ5)
	oModel:SetDescription("SOLICITAÇÃO DE RECURSOS - DESTINO")
	oModel:SetPrimaryKey( {} )

    oModel:AddGrid('ZZ6DETAIL','ZZ5MASTER', oStruZZ6,, bLinePos)
    oModel:AddGrid('ZZ62DETAIL','ZZ6DETAIL', oStruZZ62)

    oModel:SetRelation('ZZ6DETAIL', { { 'ZZ6_FILIAL', 'xFilial("ZZ6")' },;
									  { 'ZZ6_DOC', 'ZZ5_DOC'  } ,; 
                                      { 'ZZ6_TIPO', "'D'"  } },; 
		                              ZZ6->(IndexKey(3)) )

	oModel:SetRelation('ZZ62DETAIL', { { 'ZZ6_FILIAL', 'xFilial("ZZ6")' },;
									  { 'ZZ6_DOC', 'ZZ5_DOC'  } ,; 
                                      { 'ZZ6_TIPO', "'C'"  } },; 
		                              ZZ6->(IndexKey(3)) )
    oModel:GetModel('ZZ62DETAIL'):SetMaxLine( 1 )
    oModel:GetModel('ZZ5MASTER'):SetDescription("SOLICITAÇÃO DE RECURSOS")
	oModel:GetModel('ZZ6DETAIL'):SetDescription("DESTINO DOS RECURSOS-credito")
    oModel:GetModel('ZZ62DETAIL'):SetDescription("ORIGEM DOS RECURSOS-debito")
	oModel:GetModel('ZZ62DETAIL'):SetNoInsertLine( .F. )
  //Adicionando totalizadores de campos
    oModel:AddCalc('TOTAIS', 'ZZ5MASTER', 'ZZ6DETAIL', 'ZZ6_VALOR', 'XX_TOTCDS', 'SUM', , , "Total Recursos:" )
  	//oView:AddIncrementField("VIEW_ZZ5", "ZZ5_DOC")

 Return oModel


//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
Static Function ViewDef()

	Local oModel    := FWLoadModel("TINCA001")
    Local oStruZZ5  := FWFormStruct(2, 'ZZ5')
    Local oStruZZ6  := FWFormStruct(2, 'ZZ6')
    Local oStruZZ62 := FWFormStruct(2, 'ZZ6')
    Local oStruTot  := FWCalcStruct(oModel:GetModel('TOTAIS'))
	Local oView

    oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_ZZ5', oStruZZ5, 'ZZ5MASTER')

	oView:CreateHorizontalBox('SUPERIOR', 10)
	oView:CreateHorizontalBox('INFERIOR',50)
	oView:CreateHorizontalBox('BAIXO', 30)
     oView:CreateHorizontalBox("ENCH_TOT", 10)

	OView:SetOwnerView('VIEW_ZZ5', 'SUPERIOR')

	oView:AddGrid('VIEW_ZZ6', oStruZZ6, 'ZZ6DETAIL')
    oStruZZ6:RemoveField('ZZ6_DOC')
    oStruZZ6:RemoveField('ZZ6_TIPO')
	OView:SetOwnerView('VIEW_ZZ6', 'INFERIOR')
	OView:EnableTitleView('VIEW_ZZ6', 'ORIGEM DOS RECURSOS-debito')

	oView:AddGrid('VIEW_ZZ62', oStruZZ62, 'ZZ62DETAIL')
    OView:SetOwnerView('VIEW_ZZ62', 'BAIXO')
	OView:EnableTitleView('VIEW_ZZ62', 'DESTINO DOS RECURSOS-credito')
    oStruZZ62:RemoveField('ZZ6_DOC')
    oStruZZ62:RemoveField('ZZ6_TIPO')
	
    oView:AddField("VIEW_TOT", oStruTot,   "TOTAIS")
    oView:SetOwnerView("VIEW_TOT", "ENCH_TOT")

Return oView

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
Static Function TINCA01GRV(oModel)
    Local nPos   := 0
    Local nModel := 0
    Local oZZ6
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
        oZZ6 := oModel:GetModel('ZZ6DETAIL')
        If nModel == 2
            oZZ6 := oModel:GetModel('ZZ62DETAIL')
            //ZZ6->(RecLock("ZZ6", .F.))
        //Else    
            //ZZ6->(RecLock("ZZ6", .T.))
        EndIf
        For nPos := 1 To oZZ6:Length()
            oZZ6:GoLine(nPos)
            ZZ6->(RecLock("ZZ6", .T.))
            ZZ6->ZZ6_FILIAL     := xFilial('ZZ6')
            ZZ6->ZZ6_DOC        := oZZ5:GetValue('ZZ5_DOC')
            ZZ6->ZZ6_TIPO       := iIf(nModel==2,"C","D") //oZZ6:GetValue('ZZ6_TIPO')
            ZZ6->ZZ6_DATA       := oZZ6:GetValue('ZZ6_DATA')
            ZZ6->ZZ6_CLASSE     := oZZ6:GetValue('ZZ6_CLASSE')
            ZZ6->ZZ6_CO		    := oZZ6:GetValue('ZZ6_CO')
            ZZ6->ZZ6_OPERAC      := oZZ6:GetValue('ZZ6_OPERAC')
            ZZ6->ZZ6_CC          := oZZ6:GetValue('ZZ6_CC')
            ZZ6->ZZ6_ITCTA       := oZZ6:GetValue('ZZ6_ITCTA')
            ZZ6->ZZ6_CLVAL       := oZZ6:GetValue('ZZ6_CLVAL')
            ZZ6->ZZ6_VALOR       := oZZ6:GetValue('ZZ6_VALOR')
            ZZ6->ZZ6_HIST        := oZZ6:GetValue('ZZ6_HIST')
            ZZ6->ZZ6_USRAP1      := oZZ6:GetValue('ZZ6_USRAP1')
            ZZ6->ZZ6_NUSAP1      := oZZ6:GetValue('ZZ6_NUSAP1')
            ZZ6->ZZ6_STAT1       := oZZ6:GetValue('ZZ6_STAT1')
            ZZ6->ZZ6_DTAP1       := oZZ6:GetValue('ZZ6_DTAP1')
            ZZ6->ZZ6_HRAP1       := oZZ6:GetValue('ZZ6_HRAP1')
            ZZ6->ZZ6_USRAP2      := oZZ6:GetValue('ZZ6_USRAP2')
            ZZ6->ZZ6_NUSAP2      := oZZ6:GetValue('ZZ6_NUSAP2')
            ZZ6->ZZ6_STAT2       := oZZ6:GetValue('ZZ6_STAT2')
            ZZ6->ZZ6_DTAP2       := oZZ6:GetValue('ZZ6_DTAP2')
            ZZ6->ZZ6_HRAP2       := oZZ6:GetValue('ZZ6_HRAP2')
            ZZ6->ZZ6_USRCTA      := oZZ6:GetValue('ZZ6_USRCTA')
            ZZ6->ZZ6_NUSCTA      := oZZ6:GetValue('ZZ6_NUSCTA')
            ZZ6->ZZ6_STATCT      := oZZ6:GetValue('ZZ6_STATCT')
            ZZ6->ZZ6_DTCTA       := oZZ6:GetValue('ZZ6_DTCTA')
            ZZ6->ZZ6_HRCTA       := oZZ6:GetValue('ZZ6_HRCTA')  
 
           ZZ6->(MsUnlock())
        Next
    Next

Return .T.


Static Function GatZZ6(OmODEL)
Local lRet := .T.
//Local oModel := FWModelActive()
Local cDesc := oModel:GetValue('ZZ5MASTER','ZZ5_DATA')


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
    Local cAlias    := "ZZ4"

	If oModel == Nil
		Return .F.
	EndIf

	nOperation := oModel:GetOperation()

    oZZ5 := oModel:GetModel('ZZ5MASTER')

    cFilOri    := oZZ5:GetValue('ZZ5_FILIAL')
    cID        := oZZ5:GetValue('ZZ5_DOC')
    cIDDescr   := oZZ5:GetValue('ZZ5_USER')
    cdATA      := oZZ5:GetValue('ZZ5_DATA')
    
    
    oZZ6 := oModel:GetModel('ZZ6DETAIL')

    //oZZ6:SetValue('ZZ62DETAIL','ZZ6_DATA',cdATA)
 /*   
    If oZZ6:Length() > 0
        oZZ6:SetValue('ZZ6DETAIL','ZZ6_DATA',cdATA)
    For nPos := 1 To oZZ6:Length()
        oZZ6:GoLine(nPos)
        If nOperation == MODEL_OPERATION_INSERT
            oZZ6:SetValue('ZZ6DETAIL','ZZ6_DATA',cdATA)
            (cAlias)->(dbSelectArea(cAlias))
            (cAlias)->(dbSetOrder(1))
            if (cAlias)->(dbseek(xFilial(cAlias) + FwFldGet(cAlias+"_FILIAL")) + cdATA )
                cError := "Data já existe na base de dados"
                lRet := .F.
                //Exit 
            EndIf
            //oModel:SetValue('ZZ62DETAIL','ZZ6_DOC',cDesc)
            //oModel:SetValue('ZZ62DETAIL','ZZ6_DATA',cdATA)
        EndIf
    next 
    Endif   */
 /*   
       If nOperation == MODEL_OPERATION_DELETE
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


User Function SX7_Calend()
Local cAlias := "ZZ4"
Local lRet   := .T.
Local lRetorno := .F.
Local cQuery := ""
Local cData :=  DtoS(FwFldGet("ZZ6_DATA"))//DtoS(dData) 
Local cTmpZZ4 := GetNextAlias()

    (cAlias)->(dbSelectArea(cAlias))
    (cAlias)->(dbSetOrder(1))

    If FwFldGet("ZZ6_DATA") >= DDATABASE
        //u_ValidaCal(FwFldGet("ZZ6_DATA") , lRetorno )
       //cData := DtoS(FwFldGet("ZZ6_DATA"))
        cQuery := " SELECT COUNT(*) PeriodoAtivo "
        cQuery += " FROM " + RetSQLName("ZZ4") + " ZZ4 " 
        cQuery += " WHERE ZZ4.D_E_L_E_T_ = ' ' "  
        cQuery += " AND ZZ4.ZZ4_FILIAL = '" + xFilial("ZZ4") + "' "
        cQuery += " AND '" + cData + "' BETWEEN ZZ4.ZZ4_DATADE AND ZZ4.ZZ4_DATAAT " 
        cQuery += " AND ZZ4.ZZ4_STATUS = 'A' "
        
        cQuery := ChangeQuery(cQuery)
    
        If Select(cTmpZZ4) > 0
            DbSelectArea(cTmpZZ4)
            (cTmpZZ4)->(DbCloseArea())
        EndIf				
                        
        dbUseArea(.T., "TOPCONN", TcGenQry(,,cQuery), cTmpZZ4, .T., .F.)
                                    
        If (cTmpZZ4)->PeriodoAtivo > 0				
            lRet := .T.
            lRetorno := .T.
        else
            lRet := .F.	
            lRetorno := .F.										
        EndIf
 
        If !lRetorno 
            cProblema := "Data fora do prazo permitido para este lançamento. Verifique o calendário PCO."
            cSolucao  := "Digite uma data maior ou igual a data atual e que o calendario esteja Ativo."
            Help(NIL, NIL, "EXIST", NIL, cProblema, 1, 0, NIL, NIL, NIL, NIL, NIL, {cSolucao})
            lRet := .F.
        else
            lRet := .T.
        EndIf

    elseIf FwFldGet("ZZ6_DATA") < DDATABASE
        //u_ValidaCal(FwFldGet("ZZ6_DATA") , lRetorno )
       //cData := FwFldGet("ZZ6_DATA")
        cQuery := " SELECT COUNT(*) PeriodoAtivo "
        cQuery += " FROM " + RetSQLName("ZZ4") + " ZZ4 " 
        cQuery += " WHERE ZZ4.D_E_L_E_T_ = ' ' "  
        cQuery += " AND ZZ4.ZZ4_FILIAL = '" + xFilial("ZZ4") + "' "
        cQuery += " AND '" + cData + "' BETWEEN ZZ4.ZZ4_DATADE AND ZZ4.ZZ4_DATAAT " 
        cQuery += " AND ZZ4.ZZ4_STATUS = 'A' "
        
        cQuery := ChangeQuery(cQuery)
        
        If Select(cTmpZZ4) > 0
            DbSelectArea(cTmpZZ4)
            (cTmpZZ4)->(DbCloseArea())
        EndIf				
                        
        dbUseArea(.T., "TOPCONN", TcGenQry(,,cQuery), cTmpZZ4, .T., .F.)
                                    
        If (cTmpZZ4)->PeriodoAtivo > 0				
            lRet := .T.
            lRetorno := .T.
        else
            lRet := .F.	
            lRetorno := .F.										
        EndIf
 
        If !lRetorno 
            cProblema := "Data fora do prazo permitido para este lançamento. Verifique o calendário PCO."
            cSolucao  := "Digite uma data maior ou igual a data atual e que o calendario esteja Ativo."
            Help(NIL, NIL, "EXIST", NIL, cProblema, 1, 0, NIL, NIL, NIL, NIL, NIL, {cSolucao})
            lRet := .F.
        else
            lRet := .T.
        EndIf
       /*
        cProblema := "Data fora do prazo permitido para este lançamento. Verifique o calendário PCO."
        cSolucao  := "Digite uma data maior ou igual a data atual e que o calendario esteja Ativo."
        Help(NIL, NIL, "EXIST", NIL, cProblema, 1, 0, NIL, NIL, NIL, NIL, NIL, {cSolucao})
        lRet := .F.
        */
    EndIf

Return lRet
/*
User Function ValidaCal(dData, lRetorno)
Local cQuery := ""
Local cData := DtoS(dData) 
Local lRet := .F.
Local cTmpZZ4 := GetNextAlias()

    cQuery := " SELECT COUNT(*) PeriodoAtivo "
    cQuery += " FROM " + RetSQLName("ZZ4") + " ZZ4 " 
    cQuery += " WHERE ZZ4.D_E_L_E_T_ = ' ' "  
    cQuery += " AND ZZ4.ZZ4_FILIAL = '" + xFilial("ZZ4") + "' "
    cQuery += " AND '" + cData + "' BETWEEN ZZ4.ZZ4_DATADE AND ZZ4.ZZ4_DATAAT " 
    cQuery += " AND ZZ4.ZZ4_STATUS = 'A' "
    
    cQuery := ChangeQuery(cQuery)
    
    If Select(cTmpZZ4) > 0
        DbSelectArea(cTmpZZ4)
        (cTmpZZ4)->(DbCloseArea())
    EndIf				
                    
    dbUseArea(.T., "TOPCONN", TcGenQry(,,cQuery), cTmpZZ4, .T., .F.)
                                
    If (cTmpZZ4)->PeriodoAtivo > 0				
        lRet := .T.
        lRetorno := .T.
    else
        lRet := .F.	
        lRetorno := .F.										
    EndIf

Return (lRet, lRetorno)
*/

User Function ZZ6ItC()

Local lRet := .F. 
Local nRetorno := 0
/*
SELECT CTD_ITEM, CTD_DESC01, CTD.R_E_C_N_O_ AS RECNO
  FROM AKY990 AKY 
  JOIN CTD990 CTD ON CTD_FILIAL = ' ' AND CTD_ITEM BETWEEN AKY_IC_INI AND AKY_IC_FIN AND CTD.D_E_L_E_T_ = ' '
 WHERE AKY_FILIAL = ' ' AND AKY_USER = '000000' AND AKY.D_E_L_E_T_ = ' '
*/
cQuery := "SELECT ZZ6_USRAP1, AL7_USER, AKX_USER, AKY_USER, AKV_USER "
cQuery +=   "FROM " + RetSqlName("ZZ6") + " ZZ6, " + RetSqlName("AL7") + " AL7, " + RetSqlName("AKX") + " AKX, " + RetSqlName("AKY") + " AKY, " + RetSqlName("AKV") + " AKV "
cQuery +=  "WHERE ZZ6.D_E_L_E_T_ = ' ' AND ZZ6_FILIAL = '" + xFilial("ZZ6") + "' AND AL7_FILIAL = '" + xFilial("AL7") + "' AND AKX_FILIAL = '" + xFilial("AKX") + "' AND AKY_FILIAL = '" + xFilial("AKY") + "' AND AKV_FILIAL = '" + xFilial("AKV") + "' "
//cQuery +=  "GROUP BY PDG_PONTUA"

If JurF3Qry(cQuery, "ZZ6QRY", "ZZ6", @nRetorno,, /*{ "ZZ6_USRAP1", "ZZ6_UNSAP1" }*/)
	ZZ6->(DbGoto(nRetorno))
	lRet := .T.
EndIf

Return lRet

//u_retVal(FwFldGet("ZZ6_VALOR"))
User Function retVal(nSaldo)
    local cQuery := ''
    Local cConta := FwFldGet("ZZ6_CO")//'433003' //AHOR'
    Local dDataDe := DtoS(FirstDate(FwFldGet("ZZ6_DATA"))) //'20220510'
    Local dDataAte := DtoS(FwFldGet("ZZ6_DATA")) //'20220510'
    Local cTpSald := 'SL'
    Local cCC := FwFldGet("ZZ6_CC")//'AHOR'
    Local nSaldoSL1 := 0
    Local nSaldoSL2 := 0
    Default nSaldo := 0

    cQuery := " SELECT "
    cQuery += " AKD_FILIAL, "
    cQuery += " AKD_CO, "
    cQuery += " AKD_CC, "
    cQuery += " SUM(CASE WHEN AKD_TPSALD= '" + cTpSald + "' AND AKD_TIPO = '1' THEN AKD_VALOR1 * (CASE WHEN AKD_TIPO='1' THEN 1 ELSE -1 END) ELSE 0 END) as SL1, "
    cQuery += " SUM(CASE WHEN AKD_TPSALD= '" + cTpSald + "' AND AKD_TIPO = '2' THEN AKD_VALOR1 * (CASE WHEN AKD_TIPO='1' THEN 1 ELSE -1 END) ELSE 0 END) as SL2  "
    cQuery += " FROM " + RETSQLTAB('AKD') 
    cQuery += " WHERE "
    cQuery += " AKD_DATA BETWEEN '" + dDataDe + "' AND '" + dDataAte + "' AND " 
    cQuery += " AKD_CO = '" + cConta + "' AND "
    cQuery += " AKD_CC = '" + cCC + "' AND "
    cQuery += " D_E_L_E_T_ = '' "
		
    cQuery += " GROUP BY AKD_FILIAL,AKD_CO,AKD_CC,AKD_VALOR1, AKD_TPSALD "
    cQuery += " ORDER BY AKD_CC "

   
    cQuery := ChangeQuery( cQuery )       
    dbUseArea( .T., "TopConn", TCGenQry(,,cQuery),"QRYTRB", .F., .F. )
    
    While QRYTRB->( !Eof() )
        nSaldoSL1 += QRYTRB->SL1 
        nSaldoSL1 += QRYTRB->SL2
    
        QRYTRB->( dbSkip() )
    End
    nSaldo := nSaldoSL1 + nSaldoSL2

    QRYTRB->( dbCloseArea() )
    MsgInfo("Saldo disponivel no momento: R$ " +  Str(nSaldo,16,2), "SALDO")
Return (nSaldo)


/*/{Protheus.doc} zz6bLinP
Função chamada ao trocar de linha na grid (bloco bLinePos)
@type function
@author Antonio Nunes O Jr
@since 21/08/2022
@version 1.0
/*/
User Function zz6bLinP(oModel)
    Local oZZ6  := oModel:GetModel('ZZ6DETAIL')
    Local oZZ62 := oModel:GetModel('ZZ62DETAIL')
    Local nOperation := oModel:GetOperation()
    Local lRet       := .T.
    Local nValor1    := oZZ6:GetValue("ZZ6_VALOR")
    Local nValor2    := oZZ62:GetValue("ZZ6_VALOR")
    Local nPos := 0
    Local nValAtu := 0
    Local nTotal := oModel:GetModel('TOTAIS'):GetValue('XX_TOTCDS')
    //Se não for exclusão e nem visualização
    If 	nOperation != MODEL_OPERATION_DELETE .And. nOperation != MODEL_OPERATION_VIEW

 /*       For nPos := 1 To oZZ6:Length()
            oZZ6:GoLine(nPos)
            nValor1    := oZZ6:GetValue("ZZ6_VALOR")
            nValAtu += nValor1 //+ nValor2
        Next
  *///    nTotal := oModel:GetModel('TOTAIS'):GetValue('XX_TOTCDS')
        //oZZ62:SetValue("ZZ6_VALOR", nTotal )
        oModel:SetValue('ZZ62DETAIL',"ZZ6_VALOR" ,nTotal )
    EndIf

Return lRet


Static Function TINCA01POS(oModel)

    oZZ5 := oModel:GetModel('ZZ5MASTER')
    oZZ5:SetValue('ZZ5_HORA',Time())

    oZZ62 := oModel:GetModel('ZZ62DETAIL')
    oZZ62:SetValue('ZZ6_DATA',Date())
  
Return .t.


u_LerValor()

oModel:GetValue("ZZ6DETAIL","ZZ6_VALOR","ZZ6_VALOR")
//Local oModel 		:= FwModelActive()
oModel:SetValue("ZZ62DETAIL","ZZ6_VALOR","ZZ6_VALOR")

RETURN
