#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Cadastro das incorporações a serem executadas
@author  	Wagner Mobile Costa
@version 	P12
@since   	18/11/2020
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function TINCA001()
	Local oBrowse
	Local aArea	:= GetArea()
 
	DbSelectArea("ZZ5")

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('ZZ5')
	oBrowse:SetDescription("SOLICITAÇÃO DE RECURSOS - DESTINO")
	oBrowse:DisableDetails()
	oBrowse:Activate()

	RestArea(aArea)

Return NIL


//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
			Define as operacoes da aplicacao
@author  	Wagner Mobile Costa
@version 	P12
@since   	18/11/2020
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina := {}

    ADD OPTION aRotina TITLE "Pesquisar"	        ACTION "PesqBrw"             	OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Visualizar" 	        ACTION "VIEWDEF.TINCA001" 		OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE "Incluir"    	        ACTION "VIEWDEF.TINCA001" 		OPERATION 3 ACCESS 0


Return aRotina


//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
			Contem a Construcao e Definicao do Modelo          
@author  	Wagner Mobile Costa
@version 	P12
@since   	18/11/2020
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function ModelDef()
	Local oStruZZ5 := FWFormStruct( 1, 'ZZ5' )
	Local oStruZZ6 := FWFormStruct( 1, 'ZZ6' )
    Local oStruZZ62 := FWFormStruct( 1, 'ZZ6' )
    // MPFORMMODEL():New(< cID >, < bPre >, < bPost >, < bCommit >, < bCancel >)-> NIL
	Local oModel   := MPFormModel():New('TINCM001',/* { |oModel|GatZZ6()}*/, { |oModel| TINCA01POS(oModel)}, { |oModel| TINCA01GRV(oModel)})
    Local oCommit  := TINCA001EV():New()
	/*
 aAux := {} 
 aAux := FWStruTrigger('ZZ5_DOC','ZZ6_DOC','GatZZ6(M->ZZ5_DOC)',.F.) 
 oStruZA4:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4]) 
 */
 // //oStruct:AddTrigger("Campo Origem", "Campo Destino", "Bloco de código na validação da execução do gatilho", "Bloco de código na execução do gatilho")

	oModel:AddFields( 'ZZ5MASTER',, oStruZZ5)
	oModel:SetDescription("DESTINO")
	oModel:SetPrimaryKey( {} )

	oModel:AddGrid('ZZ6DETAIL', 'ZZ5MASTER', oStruZZ6,;
                { |oModelGrid, nLine ,cAction,cField| VldGrid(oModelGrid, nLine, cAction, cField) })

	oModel:AddGrid('ZZ62DETAIL', 'ZZ6DETAIL', oStruZZ6,;
                { |oModelGrid, nLine ,cAction,cField| VldGrid(oModelGrid, nLine, cAction, cField) })

	oModel:GetModel('ZZ6DETAIL'):SetUniqueLine({"ZZ6_DOC"})
    oModel:GetModel('ZZ62DETAIL'):SetUniqueLine({"ZZ6_DOC"})
	oModel:SetRelation('ZZ6DETAIL', { { 'ZZ6_FILIAL', 'xFilial("ZZ6")' },;
									  { 'ZZ6_DOC', 'ZZ5_DOC'  } },; 
		                              ZZ6->(IndexKey(1)) )
	    
        	oModel:SetRelation('ZZ62DETAIL', { { 'ZZ6_FILIAL', 'xFilial("ZZ6")' },;
									  { 'ZZ6_DOC', 'ZZ5_DOC'  } },; 
		                              ZZ6->(IndexKey(1)) )
    oModel:GetModel('ZZ5MASTER'):SetDescription("SOLICITAÇÃO DE RECURSOS")
	oModel:GetModel('ZZ6DETAIL'):SetDescription("DESTINO - CREDITO")
    oModel:GetModel('ZZ62DETAIL'):SetDescription("ORIGEM - DEBITO")
 //   oModel:InstallEvent("TINCA001EV", /*cOwner*/, oCommit)

 Return oModel


//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
			Construcao da View
@author  	Wagner Mobile Costa
@version 	P12
@since   	18/11/2020
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function ViewDef()

	Local oModel  := FWLoadModel("TINCA001")
    Local oStruZZ5 := FWFormStruct(2, 'ZZ5')
    Local oStruZZ6 := FWFormStruct(2, 'ZZ6')
        Local oStruZZ62 := FWFormStruct(2, 'ZZ6')
	Local oView

   // oStruZZ6:RemoveField('ZZ6_IDPROC')
    oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_ZZ5', oStruZZ5, 'ZZ5MASTER')

	oView:CreateHorizontalBox('SUPERIOR', 30)
	oView:CreateHorizontalBox('INFERIOR', 50)
	oView:CreateHorizontalBox('BAIXO', 20)

	OView:SetOwnerView('VIEW_ZZ5', 'SUPERIOR')

	oView:AddGrid('VIEW_ZZ6', oStruZZ6, 'ZZ6DETAIL')

	OView:SetOwnerView('VIEW_ZZ6', 'INFERIOR')
	OView:EnableTitleView('VIEW_ZZ6', 'ORIGEM - DEBITO')

	oView:AddGrid('VIEW_ZZ62', oStruZZ62, 'ZZ62DETAIL')
    OView:SetOwnerView('VIEW_ZZ62', 'BAIXO')
	OView:EnableTitleView('VIEW_ZZ62', 'DESTINO - CREDITO')

	//oView:SetViewCanActivate({|oView| VldView(oView)})
    
	//oView:AddUserButton( 'Registros Incorporação', 'CLIPS', {|oView| U_TINCMON(oView)} )

Return oView

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} Function
Validacao

@author  	Wagner Mobile Costa
@version 	P12
@since   	25/01/2021
/*/
//-----------------------------------------------------------------------------
Static Function VldView(oView)

    Local oModel	:= oView:GetModel()
    Local nOpc	    := oModel:GetOperation()
    Local oMdlPHG	:= oModel:GetModel("ZZ6DETAIL")
    Local lSemEdit  := .F.

    // Não permite edição caso já iniciou a simulação/execução
    If nOpc <> MODEL_OPERATION_INSERT
        ZZ6->(DbSeek(xFilial("ZZ6") + ZZ5->ZZ5_IDPROC))
        While ZZ6->ZZ6_FILIAL == xFilial("ZZ6") .And. ZZ6->ZZ6_DOC == ZZ5->ZZ5_DOC .And.;
            ! ZZ6->(Eof())
           If ZZ6->ZZ6_TIPO == "D"
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
/*/ {Protheus.doc} Function
Validacao ação do GRID

@author  	Wagner Mobile Costa
@version 	P12
@since   	25/01/2021
/*/
//-----------------------------------------------------------------------------
Static Function VldGrid(oModelGrid, nLine, cAction, cField)

Local lRet := .T.
Local cMsg := ""
 
If  (cAction == "DELETE" .Or. cAction == "CANSETVALUE") .And.;
    (oModelGrid:GetValue("ZZ6_TIPO") == "C")
    lRet := .F.
    If cAction == "DELETE"
        cMsg := "Carga de Registros já realizada"
        If oModelGrid:GetValue("ZZ6_TIPO") == "D"
            cMsg := "Execução já iniciada"
        EndIF
        cMsg := "Rotina: " + oModelGrid:GetValue("ZZ6_DOC") + "-" + cMsg + " a exclusão não pode ser realizada !"
        Help(,, "PCO JA INSERIDO",, cMsg, 1, 0) 
    EndIf
EndIf
*/
Return lRet

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} Function
Validacao

@author  	Wagner Mobile Costa
@version 	P12
@since   	18/11/2020
@return 	oModel
/*/
//-----------------------------------------------------------------------------
Static Function TINCA01POS(oModel)
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
    
    oZZ6 := oModel:GetModel('ZZ6DETAIL')
    For nPos := 1 To oZZ6:Length()
        oZZ6:GoLine(nPos)
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

 /*   If ! Empty(cError)
        Help(,, "Incorporador",, cError, 1, 0) 
    Else
        cRet := SendToken(cID,__cUserID,cFilOri,cFilDes,cIDDescr) 
        If empty(cRet)   
            Help(,, "Incorporador",, "Problemas no envio de email com o Token.", 1, 0) 
        Endif
    EndIf
*/
Return Empty(cError)

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} Function
Validacao

@author  	Wagner Mobile Costa
@version 	P12
@since   	18/11/2020
@return 	oModel
/*/
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
    
    For nModel := 1 To 2
        oZZ6 := oModel:GetModel('ZZ6DETAIL')
        If nModel == 2
            oZZ6 := oModel:GetModel('ZZ62DETAIL')
        EndIf
        For nPos := 1 To oZZ6:Length()
            oZZ6:GoLine(nPos)

            ZZ6->(RecLock("ZZ6", .T.))
            ZZ6->ZZ6_FILIAL := xFilial('ZZ6')
            ZZ6->ZZ6_DOC    := oZZ6:GetValue('ZZ6_DOC')
            ZZ6->ZZ6_TIPO   := oZZ6:GetValue('ZZ6_TIPO')
            ZZ6->ZZ6_DATA   := oZZ6:GetValue('ZZ6_DATA')
        Next
    Next

Return .T.


//-----------------------------------------------------------------------------
/*/ {Protheus.doc} Function
Execução da Transferencia

@author  	Wagner Mobile Costa
@version 	P12
@since   	19/11/2020
/*/
//-----------------------------------------------------------------------------

User Function TINCLG()
    Local lRet := .T.
    Private lAbortPrint := .F.

    If Select("QRY") > 0
        QRY->(DbCloseArea())
    EndIf

    BeginSQL Alias "QRY"
        SELECT ZZ5_FILIAL, ZZ5_DOC, ZZ6_TIPO, ZZ6_DATA,
          FROM %table:ZZ5% ZZ5
          JOIN %table:ZZ6% ZZ6 ON ZZ6_FILIAL = ZZ5_FILIAL AND ZZ6_DOC = ZZ5_DOC
           AND ZZ6.%notDel%
         WHERE ZZ5_FILIAL = %exp:xFilial('ZZ5')% AND ZZ5_DOC <> %exp:ZZ5->ZZ5_DOC% 
            AND ZZ5.%notDel%
         ORDER BY ZZ5_DOC, ZZ6_TIPO, ZZ6_DATA
    EndSql

    If ! Empty(QRY->ZZ5_DOC)
 /*       MsgAlert("Processo " + QRY->ZZ5_IDPROC + "/" + Alltrim(QRY->ZZ5_DESCRI) + " - Rotina: " +;
                               QRY->ZZ6_CODROT + "/" + Alltrim(QRY->ZZ6_DESC) + " - Status: " +;
                               Alltrim(QRY->STSSIMU) + If(Empty(QRY->STSSIMU), QRY->STSEXEC, "") +;
                               " deve ser finalizado para que o processo atual possa ser iniciado !" )
  */      lRet := .F.
    EndIf
    QRY->(DbCloseArea())
    If ! lRet
        Return .F.
    EndIf

    If ! MsgYesNO("Confirma a geração dos registros para Incorporação ?")
	    Return
    EndIf
    
    Processa({|| IncLog() },,,.T.)
    
    
Return 


Static Function IncLog()   
    Local cId     := ZZ5->ZZ5_DOC
    Local cRotLog := ""
    Local aPar    := {}
    Local cPar    := ""
    Local bBloco  := {|| .t. }
    Local cBloco  := ""
    Local np      := 0
    Local aPergunte := {}

    ProcRegua(1)

    ZZ6->(DbSetOrder(1))
    ZZ6->(DbSeek(xFilial("ZZ6") + cId))
    While ZZ6->( !Eof() .and. ZZ6_FILIAL + ZZ6_DOC == xFilial("ZZ6") + cId)
        cRotLog := Alltrim(ZZ6->ZZ6_HIST)
        
        np:= At("(", cRotLog)
        If np > 0
            cRotLog := Left(cRotLog, np -1)
        EndIf 

        If Empty(cRotLog)
            ZZ6->(DbSkip())
            Loop 
        EndIf   
   
        aPar := {ZZ6->ZZ6_DOC, ZZ6->ZZ6_USER, aPergunte}
        cPar := FwJsonSerialize(aPar)

        cBloco := "{ ||" + cRotLog + "('" + cPar + "')}"
        bBloco := &(cBloco)

        Processa( bBloco ,,, .T.)
        
        U_TINCRFSH()

        ZZ6->(DbSkip())
    End 
               

Return 

User Function TINCEXE(lSimula,cMono)
    
    Local aPergunte := LoadSX1(lSimula)
    Default cMono := ""
    Private lAbortPrint := .F.
    
    If aPergunte == Nil
        Return
    EndIf

  return 

/*/{Protheus.doc} LoadSX1
    (long_description)
    @since 12/02/2021
    @version version
    @param lSimula, Logico, Indica se a execução será para simulação
/*/
Static Function LoadSX1(lSimula)

    Local cPGJ_PERG  := If(lSimula, "PGJ_PERGSM", "PGJ_PERGEX")
    Local aPergunte  := {}
    // Verifica se as rotinas tem grupo de perguntas vinculado [PGJ_PERGSM ou PGJ_PERGEX]
    // Rotinas
    PGJ->(DbSetOrder(1))

    // Rotinas do Processo
    ZZ6->(DbSetOrder(1))
    ZZ6->(DbSeek(xFilial("ZZ6") + ZZ5->ZZ5_IDPROC))
    While ZZ6->( !Eof() .and. ZZ6_FILIAL + ZZ6_IDPROC == xFilial("ZZ6") + ZZ5->ZZ5_IDPROC)

        If lSimula
            If ZZ6->ZZ6_STSIMU == "3" //concluido
                ZZ6->(DbSkip())
                Loop 
            EndIf  
        Else
            If ZZ6->ZZ6_STSIMU != "3"
               Exit 
            EndIf 
            If ZZ6->ZZ6_STEXEC == "3" //concluido
                ZZ6->(DbSkip())
                Loop 
            EndIf  
        EndIf

        // Verifica se a rotina tem perguntas e carrega
        If ! U_TIncLSX1(cPGJ_PERG, @aPergunte)
            Return
        EndIF

        ZZ6->(DbSkip())
    EndDo

Return aPergunte

/*
 Funcoes para uso em multithread
*/


User Function TIncMom()
    Local cTitulo := "Incorporador"
    Local cChave := "INCORPORADOR"
  /*  Local cRotJob:= "U_TINCJOB"
    Local cRotThr:= "U_TINCTHR"
    Local cRotPar:= "U_TINCPAR"
    Local cRotErr:= "U_TINCERR" 
    Local cRotEnd:= "U_TINCEND" 
    Local nqThread := 10

    U_TGCVJMON(cTitulo, cChave, nqThread, cRotJob, cRotThr, cRotPar, cRotErr, cRotEnd )
   */ 
Return 


User Function TINCPAR(cChave)
    Local aParamBox := {}
    Local aCombo    := {"Sim","Não"}
    Local aRet      := {}
    Local aRetPar   := {}
    Local cIdProc   := Space(6)
    Local cSimula   := ""
    Local aPergunte := {}
    
    PRIVATE lMsHelpAuto := .F.

    MV_PAR01 := ""
    MV_PAR02 := .T. 
    
    aAdd(aParamBox,{1,"ID processo" , cIdProc , "999999"    ,              ,  , , 50, .T.})
    aAdd(aParamBox,{2,"Simulação"   , "Sim" , aCombo , 50 ,"" ,.F.})
    
    If ! ParamBox(aParamBox, "Parametros - Monitor", @aRet) 
        Return {}
    EndIf

    cIdProc := MV_PAR01
    cSimula := mv_par02

    ZZ6->(DbSetOrder(1))
    If ! ZZ6->(DbSeek(xFilial("ZZ6") + cIdProc))
        MsgAlert("Processo incorporador com id " + cIdProc + " não encontrado!")
        Return {}
    EndIf 

    aPar := U_JLoadPar(cChave) 

    aPergunte := LoadSX1(Left(cSimula, 1) == "S")
    If aPergunte == Nil
        Return {}
    ElseIf Len(aPar) > 3 .And. Len(aPar[3]) > 0 .And. Len(aPergunte) = 0
        aPergunte := AClone(aPar[3])
    EndIf

    aRetPar := {cIdProc, cSimula, aPergunte }

Return aclone(aRetPar)

User Function TINCEND(cChave)
    Local aPar := {} 

    aPar := U_JLoadPar(cChave) 
    If len(aPar) == 0
        Return 
    EndIf 

    ZZ5->(DbSetOrder(1))
    ZZ5->(DbSeek(xFilial("ZZ5") + aPar[1]))
    U_TZZ6RFSH()

Return 


Static Function IncStart(lSimula, aPergunte, cMono)
    Local nqThread  := 10
    Local cChave    := "INCORPORADOR"
    Local cChaveSrv := "SRV_" + cChave
  /*  Local cRotJob   := "U_TINCJOB"
    Local cRotThr   := "U_TINCTHR"
    Local cRotErr   := "U_TINCERR"
    Local cRotEnd   := "U_TINCEND"
    Local aPar      := {}
   */ Local cIdProc   := ZZ5->ZZ5_DOC
	Default cMono   := ""

    Private lAbortPrint := .F.
    
Return


User Function TIncRun()
    Local cTitulo := "Incorporador"
    Local cChave := "INCORPORADOR"

    Local oPanel1
    Local oDlg                 
    Local lOk   := .F.    
    
    Local oTimer  

    Local oRodaPe 
    Local oFontB := TFont():New('Consolas',, 16,, .T.,,,,, .F., .F.)  
           
    Private lOnline := .F.

    //lOnline:= U_JOnLine(cChave)
    
    
    DEFINE MSDIALOG oDlg TITLE "Processando Threads - " + cTitulo  FROM 0, 0 TO 380, 560 PIXEL OF oMainWnd

        oPanel1 :=TPanel():New( 010, 010, ,oDlg, , , , , , 14, 14, .F.,.T. )
        oPanel1 :align := CONTROL_ALIGN_TOP

        oBPS1  := THButton():New(002, 002, "Ocultar"   , oPanel1, {|| oDlg:End()   }, 50, 10, oFontB, "Fechar essa janela e permitir a execução do job") 
        oBPS2  := THButton():New(002, 052, "Finalizar" , oPanel1, {|| Finaliza(cChave)         }, 40, 10, oFontB, "Parar o serviço de execução do job") 
        oBPS3  := THButton():New(002, 092, "Monitor"   , oPanel1, {|| U_TIncMom()  }, 40, 10, oFontB, "Monitor threads") 

         
        oRodaPe:= TSimpleEditor():New( 0,0,oDlg, 40, 40 )
        oRodaPe:Align := CONTROL_ALIGN_ALLCLIENT
        
        DEFINE TIMER oTimer INTERVAL 1000 ACTION AtuTela2(oTimer, oDlg, cTitulo, cChave, oRodaPe ) OF oDlg

    ACTIVATE MSDIALOG oDlg ON INIT (AtuTela2(oTimer, oDlg,  cTitulo, cChave, oRodaPe), oTimer:Activate())  CENTERED
    
 
Return  lOk    

Static Function AtuTela2(oTimer, oDlg, cTitulo, cChave, oRodaPe)
    Local cChaveSrv := "SRV_" + cChave 
    
    If oTimer == NIL
        Return
    EndIf 
    
    oTimer:Deactivate()   
    lOnline:= U_JOnLine(cChave)
    
    cMsgSrv := U_JMsg(cChaveSrv)

    oRodaPe:Load(MontaHtml(cChaveSrv, cMsgSrv, lOnline))
    oRodaPe:Refresh()

    oDlg:cCaption := "Processamento Threads  - " + cTitulo + " - " + Time() +If(lOnline," - (On Line) ", " - (Off Line)")
  
    oTimer:Activate()

Return

Static Function Finaliza(cChave)
    If MsgYesNo("Confirma a desativação do serviço")
        U_JSaveArq("SRV_" + cChave + ".fim", "Fim") 
    Endif

Return 

Static Function MontaHtml(cChaveSrv, cMsgSrv, lOnline)
    Local aInfo := U_JSrvGetInfo(cChaveSrv)

    Local nTCapa   := aInfo[1]
    Local nLimite  := aInfo[2]
    Local nCount   := aInfo[3]
    Local nQtdGo   := aInfo[4]
    Local nQtdProc := aInfo[5]
    Local nQtdErro := aInfo[6]
    Local cIdProc  := Subs(cMsgSrv, 4, 6)
    Local aQtdes   := BuscQtd(cIdProc)

    Local nQtdDoc   :=  0
    Local nQtdIniS  :=  0
    Local nQtdConS  :=  0
    Local nQtdocoS  :=  0
    Local nQtdNProS :=  0
    Local nQtdIgnora:=  0
    Local nQtdIni   :=  0
    Local nQtdCon   :=  0
    Local nQtdOco   :=  0
    Local nQtdNPro  :=  0
    Local nPSimu    :=  0
    Local nPExec    :=  0



    nQtdDoc   := aQtdes[1]
    nQtdIniS  := aQtdes[2]
    nQtdConS  := aQtdes[3]
    nQtdOcoS  := aQtdes[4]
    nQtdNProS := aQtdes[5]
    nQtdIgnora:= aQtdes[6]
    nQtdIni   := aQtdes[7]
    nQtdCon   := aQtdes[8]
    nQtdOco   := aQtdes[9]
    nQtdNPro  := aQtdes[10]

    nPSimu := Int((nQtdConS + nQtdIgnora) / nQtdDoc * 100)
    nPExec := Int((nQtdCon  + nQtdIgnora) / nQtdDoc * 100)

    cHtml := ""
    cHtml += "<br>" + CRLF
    If lOnline
        cHtml += "<font COLOR='GREEN'><b>On Line</b></font>"
    Else 
        cHtml += "<font COLOR='RED'><b>OFF Line</b></font>"
    EndIf 

    cHtml += "<br>" + CRLF
    cHtml += "   <table width=100% border=0 cellspacing=0 cellpadding=2 bordercolor='666633'>" + CRLF
    cHtml += "      <tr><td width='150' align='LEFT'><b>Mensagem</b></td>                <td width='300' align='LEFT'> " + cMsgSrv  +"</td></tr>" + CRLF
    cHtml += "      <tr><td width='150' align='LEFT'><b>ID</b></td>                      <td width='100' align='LEFT'> " + cIDProc  +"</td></tr>" + CRLF
    cHtml += "      <tr><td width='150' align='LEFT'><b>Qtde documentos</b></td>         <td width='100' align='LEFT'> " + Alltrim(Transform(nQtdDoc    , "@e 99,999,999,999"))  +"</td></tr>" + CRLF
    cHtml += "      <tr><td width='150' align='LEFT'><b>Qtde ignorados </b></td>         <td width='100' align='LEFT'> " + Alltrim(Transform(nQtdIgnora , "@e 99,999,999,999"))  +"</td></tr>" + CRLF
    cHtml += "   </table>" + CRLF
    
    cHtml += "<br>" + CRLF
	
    cHtml += "   <table width=100% border=1 cellspacing=0 cellpadding=2 bordercolor='666633'>" + CRLF
    cHtml += "      <tr>" + CRLF
    cHtml += "      <td width='100' align='LEFT'> </td>" + CRLF
    cHtml += "      <td width='100' align='LEFT'><b>Concluidos     </b></td> " + CRLF
    cHtml += "      <td width='100' align='LEFT'><b>Ocorrencias    </b></td> " + CRLF
    cHtml += "      <td width='100' align='LEFT'><b>Não processados</b></td> " + CRLF
    cHtml += "      <td width='100' align='LEFT'><b>% Conclusão    </b></td> " + CRLF
    cHtml += "      </tr>" + CRLF
    cHtml += "      <tr>" + CRLF
    cHtml += "      <td width='100' align='LEFT'><b>Simulação      </b></td>"+ CRLF
    cHtml += "      <td width='100' align='LEFT'> " + Alltrim(Transform(nQtdConS  , "@e 99,999,999,999"))  +"</td>" + CRLF
    cHtml += "      <td width='100' align='LEFT'> " + Alltrim(Transform(nQtdOcoS  , "@e 99,999,999,999"))  +"</td>" + CRLF
    cHtml += "      <td width='100' align='LEFT'> " + Alltrim(Transform(nQtdNProS , "@e 99,999,999,999"))  +"</td>" + CRLF
    cHtml += "      <td width='100' align='LEFT'> " + Alltrim(Transform(nPSimu , "@e 999"))  +"</td>" + CRLF
    cHtml += "      </tr>" + CRLF
    cHtml += "      <tr>" + CRLF
    cHtml += "      <td width='100' align='LEFT'><b>Efetivação     </b></td>" + CRLF
    cHtml += "      <td width='100' align='LEFT'> " + Alltrim(Transform(nQtdCon  , "@e 99,999,999,999"))  +"</td>" + CRLF
    cHtml += "      <td width='100' align='LEFT'> " + Alltrim(Transform(nQtdOco  , "@e 99,999,999,999"))  +"</td>" + CRLF
    cHtml += "      <td width='100' align='LEFT'> " + Alltrim(Transform(nQtdNPro , "@e 99,999,999,999"))  +"</td>" + CRLF
    cHtml += "      <td width='100' align='LEFT'> " + Alltrim(Transform(nPExec   , "@e 999"))  +"</td>" + CRLF
    cHtml += "      </tr>" + CRLF
    cHtml += "   </table>" + CRLF
    cHtml += "<br>" + CRLF
    cHtml += "<br>" + CRLF

    cHtml += "<b>Job em Execução - Threads</b>" + CRLF
    cHtml += "   <table width=100% border=1 cellspacing=0 cellpadding=2 bordercolor='666633'>" + CRLF
    cHtml += "      <tr><td width='150' align='LEFT'><b>Capacidade</b></td>      <td width='150' align='LEFT'> " + Alltrim(Transform(nTCapa  , "@e 99,999,999,999"))  +"</td></tr>" + CRLF
    cHtml += "      <tr><td width='150' align='LEFT'><b>Disponibilidade</b></td> <td width='150' align='LEFT'> " + Alltrim(Transform(nLimite , "@e 99,999,999,999"))  +"</td></tr>" + CRLF
    cHtml += "      <tr><td width='150' align='LEFT'><b>Iniciadas</b></td>       <td width='150' align='LEFT'> " + Alltrim(Transform(nCount  , "@e 99,999,999,999"))  +"</td></tr>" + CRLF
    cHtml += "      <tr><td width='150' align='LEFT'><b>Distribuidos</b></td>    <td width='150' align='LEFT'> " + Alltrim(Transform(nQtdGo  , "@e 99,999,999,999"))  +"</td></tr>" + CRLF
    cHtml += "      <tr><td width='150' align='LEFT'><b>Processados</b></td>     <td width='150' align='LEFT'> " + Alltrim(Transform(nQtdProc, "@e 99,999,999,999"))  +"</td></tr>" + CRLF
    cHtml += "      <tr><td width='150' align='LEFT'><b>Erros</b></td>           <td width='150' align='LEFT'> " + Alltrim(Transform(nQtdErro, "@e 99,999,999,999"))  +"</td></tr>" + CRLF
    cHtml += "   </table>" + CRLF

Return cHtml 


Static Function BuscQtd(cIdProc)
    Local clAlias := GetNextAlias()
	Local cQuery := ""	
    Local aArea  := GetArea()
    Local aQtdes := {}    
    cQuery := MontaQry(cIDProc) 
    
    dbUseArea( .T., __cRdd, TcGenQry( ,, cQuery ), clAlias, .T., .F. )
    If (clAlias)->(Eof())
        (clAlias)->(dbCloseArea())
        RestArea(aArea)
        Return {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    EndIf 

    aadd(aQtdes, (clAlias)->QREG    )    
    aadd(aQtdes, (clAlias)->QINI_S  )    
    aadd(aQtdes, (clAlias)->QCONC_S )    
    aadd(aQtdes, (clAlias)->QERRO_S )    
    aadd(aQtdes, (clAlias)->QNPROC_S)    
    aadd(aQtdes, (clAlias)->QIGNORA )    
    aadd(aQtdes, (clAlias)->QINI    )    
    aadd(aQtdes, (clAlias)->QCONC   )    
    aadd(aQtdes, (clAlias)->QERRO   )    
    aadd(aQtdes, (clAlias)->QNPROC  )    
   
    (clAlias)->(dbCloseArea())
    RestArea(aArea)
Return aQtdes



Static Function MontaQry(cIDProc) 
    Local cQuery := ""

    cQuery := " "
    cQuery += " SELECT  " 
    cQuery += "         (SELECT COUNT(1)        FROM " + RetSQLName("PGI") + " A WHERE  A.PGI_FILIAL = '" + FWxFilial("PGI") + "' AND A.PGI_IDPROC = '" + cIDProc + "'                         AND A.D_E_L_E_T_ = ' ' )  AS QREG    ,  " 
    cQuery += "         (SELECT COUNT(1)        FROM " + RetSQLName("PGI") + " A WHERE  A.PGI_FILIAL = '" + FWxFilial("PGI") + "' AND A.PGI_IDPROC = '" + cIDProc + "' AND A.PGI_STSIMU =  '2' AND A.D_E_L_E_T_ = ' ' )  AS QINI_S  ,  " 
    cQuery += "         (SELECT COUNT(1)        FROM " + RetSQLName("PGI") + " A WHERE  A.PGI_FILIAL = '" + FWxFilial("PGI") + "' AND A.PGI_IDPROC = '" + cIDProc + "' AND A.PGI_STSIMU =  '3' AND A.D_E_L_E_T_ = ' ' )  AS QCONC_S ,  " 
    cQuery += "         (SELECT COUNT(1)        FROM " + RetSQLName("PGI") + " A WHERE  A.PGI_FILIAL = '" + FWxFilial("PGI") + "' AND A.PGI_IDPROC = '" + cIDProc + "' AND A.PGI_STSIMU =  '4' AND A.D_E_L_E_T_ = ' ' )  AS QERRO_S ,  " 
    cQuery += "         (SELECT COUNT(1)        FROM " + RetSQLName("PGI") + " A WHERE  A.PGI_FILIAL = '" + FWxFilial("PGI") + "' AND A.PGI_IDPROC = '" + cIDProc + "' AND A.PGI_STSIMU =  '1' AND A.D_E_L_E_T_ = ' ' )  AS QNPROC_S,  " 
    cQuery += "         (SELECT COUNT(1)        FROM " + RetSQLName("PGI") + " A WHERE  A.PGI_FILIAL = '" + FWxFilial("PGI") + "' AND A.PGI_IDPROC = '" + cIDProc + "' AND A.PGI_STSIMU =  '5' AND A.D_E_L_E_T_ = ' ' )  AS QIGNORA ,  "     
    cQuery += "         (SELECT COUNT(1)        FROM " + RetSQLName("PGI") + " A WHERE  A.PGI_FILIAL = '" + FWxFilial("PGI") + "' AND A.PGI_IDPROC = '" + cIDProc + "' AND A.PGI_STEXEC =  '2' AND A.D_E_L_E_T_ = ' ' )  AS QINI    ,  " 
    cQuery += "         (SELECT COUNT(1)        FROM " + RetSQLName("PGI") + " A WHERE  A.PGI_FILIAL = '" + FWxFilial("PGI") + "' AND A.PGI_IDPROC = '" + cIDProc + "' AND A.PGI_STEXEC =  '3' AND A.D_E_L_E_T_ = ' ' )  AS QCONC   ,  " 
    cQuery += "         (SELECT COUNT(1)        FROM " + RetSQLName("PGI") + " A WHERE  A.PGI_FILIAL = '" + FWxFilial("PGI") + "' AND A.PGI_IDPROC = '" + cIDProc + "' AND A.PGI_STEXEC =  '4' AND A.D_E_L_E_T_ = ' ' )  AS QERRO   ,  " 
    cQuery += "         (SELECT COUNT(1)        FROM " + RetSQLName("PGI") + " A WHERE  A.PGI_FILIAL = '" + FWxFilial("PGI") + "' AND A.PGI_IDPROC = '" + cIDProc + "' AND A.PGI_STEXEC =  '1' AND A.D_E_L_E_T_ = ' ' )  AS QNPROC     " 
    cQuery += " FROM   " + RetSQLName("PGI") + " PGI   " 
    cQuery += " WHERE  PGI_FILIAL = '" + FWxFilial("PGI") + "' AND PGI_IDPROC = '" + cIDProc + "' AND PGI.D_E_L_E_T_ = ' '  " 

Return cQuery

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} Function
Validacao permissão acesso campo

@author Wagner Mobile
@version P12
@since   25/01/2021
@return  lRet
/*/
//-----------------------------------------------------------------------------
User Function TINCA01W()

    Local lRet        := .F.
    Local aArea       := GetArea()
    Local cZZ6_CODROT := FWFLDGET("ZZ6_CODROT")

    DbSelectArea("PGJ")
    DbSetOrder(1)
    If DbSeek(xFilial() + cZZ6_CODROT) .And. PGJ->PGJ_EDIT == "1"
        lRet := .T.
    EndIF

    RestArea(aArea)

Return lRet

/*/{Protheus.doc} TINCA001EV
    (long_description)
    @since 10/02/2021
    @version version
/*/
Class TINCA001EV FROM FWModelEvent
    Method New() CONSTRUCTOR
    Method AfterTTS()

ENDCLASS

/*/{Protheus.doc} New
    (long_description)
    @since 10/02/2021
    @version version
/*/
Method New() Class TINCA001EV

Return


/*/{Protheus.doc} AfterTTS
    (long_description)
    @since 10/02/2021
    @version version
    @param oModel, objeto, Objeto Model
    @param cModelId, objeto, Id do submodelo
/*/
Method AfterTTS(oModel, cModelId) Class TINCA001EV

Local cZZ5_IDPROC := ZZ5->ZZ5_IDPROC

    If oModel:GetOperation() == MODEL_OPERATION_DELETE
        TCSQLEXEC("DELETE FROM " + RetSQlName("PGI") + " WHERE PGI_FILIAL = '" + xFilial("PGI") + "' " +;
                     "AND PGI_IDPROC = '" + cZZ5_IDPROC + "'")
    EndIF

Return

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
			Cria e envia Token de segurança para o email do usuário logado
@author  	Julio Saraiva
@version 	P12
@since   	09/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function SendToken(cId,cUser,cFILORI,cFILDES,cDesc)
Local cRet      := ""
Local cAux      := ""
Local aUser := FWSFALLUSERS({cUser})
Local cEmailInc := Alltrim(aUser[1,5]) //Alltrim(PswRet()[1,14])
Local cUsrInc2  := Alltrim(aUser[1,4]) //Alltrim(PswRet()[1,4])
Local cAssunto  := "Token Incorporador | Id Processamento: " + cID + " | " + cDesc
Local cNmFilOri := " ["+AllTrim(GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFILORI, 1, "" ))+"]"
Local cNmFilDes := " ["+AllTrim(GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFILDES, 1, "" ))+"]"

Local cPathHTML := GetMV("MV_WFDIR")
Local cFileName := ""
Local cArqHTML  := "\workflow\TINCA001.html"
Local oHtml
Local cTexto    := ""

If ! File(cArqHtml)
    If ! Isblind()
	    MsgInfo("Arquivo [" + cArqHTML + "] não encontrado !")
    EndIf 
	//RestArea(aArea)
	Return
EndIf

oHtml := TWFHtml():New( cArqHTML )

cAux    := Encode64(cId+cUser+cFILORI+cFILDES)

If !Empty(cAux)
    MsgAlert("Enviando email para: "+ cEmailInc +" com o token.")
Endif

oHTML:ValByName("CUSRINC2"	,cUsrInc2)   // variáveis utilizadas no html
oHTML:ValByName("CID"	    ,cID)
oHTML:ValByName("CDESC"	    ,cDesc)
oHTML:ValByName("CFILORI"	,cFILORI)
oHTML:ValByName("CNMFILORI"	,cNmFilOri)
oHTML:ValByName("CFILDES"	,cFILDES)
oHTML:ValByName("CNMFILDES"	,cNmFilDes)
oHTML:ValByName("CAUX"	    ,cAux)

cFileName := CriaTrab(NIL,.F.) + ".htm"
cFileName := cPathHTML + "\" + cFileName 
oHtml:SaveFile(cFileName)
cRet      := WFLoadFile(cFileName)
ctexto    := StrTran(cRet,chr(13),"")
ctexto    := StrTran(cRet,chr(10),"")
cTexto    := OemtoAnsi(cTexto)

u_xSendMail(cEmailInc,cAssunto,cTexto)

Return cAux

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
			Validação do Token de segurança 
@author  	Julio Saraiva
@version 	P12
@since   	09/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function GetToken(cToken)
Local lRet := .F.
Local cResp  := Space(100)
//Local cCodigo:= ""

Local oDlg 
Local oPesq 
Local oOk
Local oCancel

Local lPesq := .F.

//cCodigo := encode64(cToken)

DEFINE MSDIALOG oDlg TITLE "Informe o Token... "   FROM 0, 0 TO 100, 300 OF GetWndDefault() STYLE DS_MODALFRAME STATUS  PIXEL

    DEFINE SBUTTON oOk     FROM 030, 50 TYPE 01 OF oDlg ENABLE ACTION ( lPesq := .T. , oDlg:End() )
    DEFINE SBUTTON oCancel FROM 030, 80 TYPE 02 OF oDlg ENABLE ACTION ( oDlg:End() )
    @ 10,10  MSGET oPesq VAR cResp	SIZE 130,010 OF oDlg PIXEL  

ACTIVATE MSDIALOG oDlg CENTERED //ON INIT EnchoiceBar( oDlg , bSet15 , bSet24 )

IF DECODE64(ALLTRIM(cResp)) == cToken .AND. lPesq
    lRet := .T.
EndIF

Return lRet


Static Function GatZZ6(OmODEL)
Local lRet := .T.
Local oModel := FWModelActive()
Local cDesc := oModel:GetValue('ZZ5MASTER','ZZ5_DOC')

oModel:SetValue('ZZ6DETAIL','ZZ6_DOC',cDesc)
oModel:SetValue('ZZ62DETAIL','ZZ6_DOC',cDesc)

Return lRet
