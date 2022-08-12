#INCLUDE "protheus.ch"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

#DEFINE CSSBOTAO	"QPushButton { color: #024670; "+;
"    border-image: url(rpo:fwstd_btn_nml.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"+;
"QPushButton:pressed {	color: #FFFFFF; "+;
"    border-image: url(rpo:fwstd_btn_prd.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"

//--------------------------------------------------------------------
/*/{Protheus.doc} UPDEXP
Fun��o de update de dicion�rios para compatibiliza��o

@author TOTVS Protheus
@since  11/08/2022
@obs    Gerado por EXPORDIC - V.7.2.0.1 EFS / Upd. V.5.2.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function UPDEXP( cEmpAmb, cFilAmb )

Local   aSay      := {}
Local   aButton   := {}
Local   aMarcadas := {}
Local   cTitulo   := "ATUALIZA��O DE DICION�RIOS E TABELAS"
Local   cDesc1    := "Esta rotina tem como fun��o fazer  a atualiza��o  dos dicion�rios do Sistema ( SX?/SIX )"
Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja n�o podem haver outros"
Local   cDesc3    := "usu�rios  ou  jobs utilizando  o sistema.  � EXTREMAMENTE recomendav�l  que  se  fa�a"
Local   cDesc4    := "um BACKUP  dos DICION�RIOS  e da  BASE DE DADOS antes desta atualiza��o, para"
Local   cDesc5    := "que caso ocorram eventuais falhas, esse backup possa ser restaurado."
Local   cDesc6    := ""
Local   cDesc7    := ""
Local   cMsg      := ""
Local   lOk       := .F.
Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )

Private oMainWnd  := NIL
Private oProcess  := NIL

#IFDEF TOP
    TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
#ENDIF

__cInterNet := NIL
__lPYME     := .F.

Set Dele On

// Mensagens de Tela Inicial
aAdd( aSay, cDesc1 )
aAdd( aSay, cDesc2 )
aAdd( aSay, cDesc3 )
aAdd( aSay, cDesc4 )
aAdd( aSay, cDesc5 )
//aAdd( aSay, cDesc6 )
//aAdd( aSay, cDesc7 )

// Botoes Tela Inicial
aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

If lAuto
	lOk := .T.
Else
	FormBatch(  cTitulo,  aSay,  aButton )
EndIf

If lOk

	If GetVersao(.F.) < "12" .OR. ( FindFunction( "MPDicInDB" ) .AND. !MPDicInDB() )
		cMsg := "Este update N�O PODE ser executado neste Ambiente." + CRLF + CRLF + ;
				"Os arquivos de dicion�rios se encontram em formato ISAM (" + GetDbExtension() + ") e este update est� preparado " + ;
				"para atualizar apenas ambientes com dicion�rios no Banco de Dados."

		If lAuto
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( "LOG DA ATUALIZA��O DOS DICION�RIOS" )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( cMsg )
			ConOut( DToC(Date()) + "|" + Time() + cMsg )
		Else
			MsgInfo( cMsg )
		EndIf

		Return NIL
	EndIf

	If lAuto
		aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
	Else

		aMarcadas := EscEmpresa()
	EndIf

	If !Empty( aMarcadas )
		If lAuto .OR. MsgNoYes( "Confirma a atualiza��o dos dicion�rios ?", cTitulo )
			oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
			oProcess:Activate()

			If lAuto
				If lOk
					MsgStop( "Atualiza��o Realizada.", "UPDEXP" )
				Else
					MsgStop( "Atualiza��o n�o Realizada.", "UPDEXP" )
				EndIf
				dbCloseAll()
			Else
				If lOk
					Final( "Atualiza��o Realizada." )
				Else
					Final( "Atualiza��o n�o Realizada." )
				EndIf
			EndIf

		Else
			Final( "Atualiza��o n�o Realizada." )

		EndIf

	Else
		Final( "Atualiza��o n�o Realizada." )

	EndIf

EndIf

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSTProc
Fun��o de processamento da grava��o dos arquivos

@author TOTVS Protheus
@since  11/08/2022
@obs    Gerado por EXPORDIC - V.7.2.0.1 EFS / Upd. V.5.2.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSTProc( lEnd, aMarcadas, lAuto )
Local   aInfo     := {}
Local   aRecnoSM0 := {}
Local   cAux      := ""
Local   cFile     := ""
Local   cFileLog  := ""
Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
Local   cTCBuild  := "TCGetBuild"
Local   cTexto    := ""
Local   cTopBuild := ""
Local   lOpen     := .F.
Local   lRet      := .T.
Local   nI        := 0
Local   nPos      := 0
Local   nRecno    := 0
Local   nX        := 0
Local   oDlg      := NIL
Local   oFont     := NIL
Local   oMemo     := NIL

Private aArqUpd   := {}

If ( lOpen := MyOpenSm0(.T.) )

	dbSelectArea( "SM0" )
	dbGoTop()

	While !SM0->( EOF() )
		// S� adiciona no aRecnoSM0 se a empresa for diferente
		If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
		   .AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
			aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
		EndIf
		SM0->( dbSkip() )
	End

	SM0->( dbCloseArea() )

	If lOpen

		For nI := 1 To Len( aRecnoSM0 )

			If !( lOpen := MyOpenSm0(.F.) )
				MsgStop( "Atualiza��o da empresa " + aRecnoSM0[nI][2] + " n�o efetuada." )
				Exit
			EndIf

			SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

			RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

			lMsFinalAuto := .F.
			lMsHelpAuto  := .F.

			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( "LOG DA ATUALIZA��O DOS DICION�RIOS" )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " " )
			AutoGrLog( " Dados Ambiente" )
			AutoGrLog( " --------------------" )
			AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
			AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
			AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
			AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
			AutoGrLog( " Data / Hora �nicio.: " + DtoC( Date() )  + " / " + Time() )
			AutoGrLog( " Environment........: " + GetEnvServer()  )
			AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
			AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
			AutoGrLog( " Vers�o.............: " + GetVersao(.T.) )
			AutoGrLog( " Usu�rio TOTVS .....: " + __cUserId + " " +  cUserName )
			AutoGrLog( " Computer Name......: " + GetComputerName() )

			aInfo   := GetUserInfo()
			If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
				AutoGrLog( " " )
				AutoGrLog( " Dados Thread" )
				AutoGrLog( " --------------------" )
				AutoGrLog( " Usu�rio da Rede....: " + aInfo[nPos][1] )
				AutoGrLog( " Esta��o............: " + aInfo[nPos][2] )
				AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
				AutoGrLog( " Environment........: " + aInfo[nPos][6] )
				AutoGrLog( " Conex�o............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
			EndIf
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " " )

			If !lAuto
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
			EndIf

			oProcess:SetRegua1( 8 )


			oProcess:IncRegua1( "Dicion�rio de arquivos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSX2()


			FSAtuSX3()


			oProcess:IncRegua1( "Dicion�rio de �ndices" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSIX()

			oProcess:IncRegua1( "Dicion�rio de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			oProcess:IncRegua2( "Atualizando campos/�ndices" )

			// Altera��o f�sica dos arquivos
			__SetX31Mode( .F. )

			If FindFunction(cTCBuild)
				cTopBuild := &cTCBuild.()
			EndIf

			For nX := 1 To Len( aArqUpd )

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
						!aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
						TcInternal( 25, "CLOB" )
					EndIf
				EndIf

				If Select( aArqUpd[nX] ) > 0
					dbSelectArea( aArqUpd[nX] )
					dbCloseArea()
				EndIf

				X31UpdTable( aArqUpd[nX] )

				If __GetX31Error()
					Alert( __GetX31Trace() )
					MsgStop( "Ocorreu um erro desconhecido durante a atualiza��o da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicion�rio e da tabela.", "ATEN��O" )
					AutoGrLog( "Ocorreu um erro desconhecido durante a atualiza��o da estrutura da tabela : " + aArqUpd[nX] )
				EndIf

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					TcInternal( 25, "OFF" )
				EndIf

			Next nX


			oProcess:IncRegua1( "Dicion�rio de par�metros" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSX6()


			oProcess:IncRegua1( "Dicion�rio de consultas padr�o" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSXB()


			oProcess:IncRegua1( "Helps de Campo" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuHlp()

			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
			AutoGrLog( Replicate( "-", 128 ) )

			RpcClearEnv()

		Next nI

		If !lAuto

			cTexto := LeLog()

			Define Font oFont Name "Mono AS" Size 5, 12

			Define MsDialog oDlg Title "Atualiza��o concluida." From 3, 0 to 340, 417 Pixel

			@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
			oMemo:bRClicked := { || AllwaysTrue() }
			oMemo:oFont     := oFont

			Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
			Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
			MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

			Activate MsDialog oDlg Center

		EndIf

	EndIf

Else

	lRet := .F.

EndIf

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX2
Fun��o de processamento da grava��o do SX2 - Arquivos

@author TOTVS Protheus
@since  11/08/2022
@obs    Gerado por EXPORDIC - V.7.2.0.1 EFS / Upd. V.5.2.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX2()
Local aEstrut   := {}
Local aSX2      := {}
Local cAlias    := ""
Local cEmpr     := ""
Local cPath     := ""
Local nI        := 0
Local nJ        := 0

AutoGrLog( "�nicio da Atualiza��o" + " SX2" + CRLF )

aEstrut := { "X2_CHAVE"  , "X2_PATH"   , "X2_ARQUIVO", "X2_NOME"   , "X2_NOMESPA", "X2_NOMEENG", "X2_MODO"   , ;
             "X2_TTS"    , "X2_ROTINA" , "X2_PYME"   , "X2_UNICO"  , "X2_DISPLAY", "X2_SYSOBJ" , "X2_USROBJ" , ;
             "X2_POSLGT" , "X2_CLOB"   , "X2_AUTREC" , "X2_MODOEMP", "X2_MODOUN" , "X2_MODULO" }


dbSelectArea( "SX2" )
SX2->( dbSetOrder( 1 ) )
SX2->( dbGoTop() )
cPath := SX2->X2_PATH
cPath := IIf( Right( AllTrim( cPath ), 1 ) <> "\", PadR( AllTrim( cPath ) + "\", Len( cPath ) ), cPath )
cEmpr := Substr( SX2->X2_ARQUIVO, 4 )

aAdd( aSX2, {'ZZ1',cPath,'ZZ1'+cEmpr,'Log Altera��es � Acesso a Enti','Log Altera��es � Acesso a Enti','Log Altera��es � Acesso a Enti','E','','','','','','','','','','','E','E',0} )
aAdd( aSX2, {'ZZ2',cPath,'ZZ2'+cEmpr,'Perfil Usu�rios PCO','Perfil Usu�rios PCO','Perfil Usu�rios PCO','E','','','','','','','','','','','E','E',0} )
aAdd( aSX2, {'ZZ3',cPath,'ZZ3'+cEmpr,'Limites de Aprova��o PCO','Limites de Aprova��o PCO','Limites de Aprova��o PCO','E','','','','','','','','','','','E','E',0} )
aAdd( aSX2, {'ZZ4',cPath,'ZZ4'+cEmpr,'Calend�rio PCO','Calend�rio PCO','Calend�rio PCO','E','','','','','','','','','','','E','E',0} )
aAdd( aSX2, {'ZZ5',cPath,'ZZ5'+cEmpr,'Cabec. Solicita��o de Recurso','Cabec. Solicita��o de Recurso','Cabec. Solicita��o de Recurso','E','','','','','','','','','','','E','E',0} )
aAdd( aSX2, {'ZZ6',cPath,'ZZ6'+cEmpr,'Itens Solicita��o de Recurso','Itens Solicita��o de Recurso','Itens Solicita��o de Recurso','E','','','','','','','','','','','E','E',0} )
aAdd( aSX2, {'ZZA',cPath,'ZZA'+cEmpr,'Grupo de Contas � Conta Or�ame','Grupo de Contas � Conta Or�ame','Grupo de Contas � Conta Or�ame','E','','','','','','','','','','','E','E',0} )
aAdd( aSX2, {'ZZB',cPath,'ZZB'+cEmpr,'Grupo de Contas � Centro de Cu','Grupo de Contas � Centro de Cu','Grupo de Contas � Centro de Cu','E','','','','','','','','','','','E','E',0} )
aAdd( aSX2, {'ZZC',cPath,'ZZC'+cEmpr,'Grupo de Contas � Item Conta','Grupo de Contas � Item Conta','Grupo de Contas � Item Conta','E','','','','','','','','','','','E','E',0} )
aAdd( aSX2, {'ZZD',cPath,'ZZD'+cEmpr,'Grupo de Contas � Classe de Va','Grupo de Contas � Classe de Va','Grupo de Contas � Classe de Va','E','','','','','','','','','','','E','E',0} )
//
// Atualizando dicion�rio
//
oProcess:SetRegua2( Len( aSX2 ) )

dbSelectArea( "SX2" )
dbSetOrder( 1 )

For nI := 1 To Len( aSX2 )

	oProcess:IncRegua2( "Atualizando Arquivos (SX2)..." )

	If !SX2->( dbSeek( aSX2[nI][1] ) )

		If !( aSX2[nI][1] $ cAlias )
			cAlias += aSX2[nI][1] + "/"
			AutoGrLog( "Foi inclu�da a tabela " + aSX2[nI][1] )
		EndIf

		RecLock( "SX2", .T. )
		For nJ := 1 To Len( aSX2[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				If AllTrim( aEstrut[nJ] ) == "X2_ARQUIVO"
					FieldPut( FieldPos( aEstrut[nJ] ), SubStr( aSX2[nI][nJ], 1, 3 ) + cEmpAnt +  "0" )
				Else
					FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
				EndIf
			EndIf
		Next nJ
		MsUnLock()

	EndIf

Next nI

AutoGrLog( CRLF + "Final da Atualiza��o" + " SX2" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX3
Fun��o de processamento da grava��o do SX3 - Campos

@author TOTVS Protheus
@since  11/08/2022
@obs    Gerado por EXPORDIC - V.7.2.0.1 EFS / Upd. V.5.2.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX3()
Local aEstrut   := {}
Local aSX3      := {}
Local cAlias    := ""
Local cAliasAtu := ""
Local cMsg      := ""
Local cSeqAtu   := ""
Local cX3Campo  := ""
Local cX3Dado   := ""
Local lTodosNao := .F.
Local lTodosSim := .F.
Local nI        := 0
Local nJ        := 0
Local nOpcA     := 0
Local nPosArq   := 0
Local nPosCpo   := 0
Local nPosOrd   := 0
Local nPosSXG   := 0
Local nPosTam   := 0
Local nPosVld   := 0
Local nSeqAtu   := 0
Local nTamSeek  := Len( SX3->X3_CAMPO )

AutoGrLog( "�nicio da Atualiza��o" + " SX3" + CRLF )

aEstrut := { { "X3_ARQUIVO", 0 }, { "X3_ORDEM"  , 0 }, { "X3_CAMPO"  , 0 }, { "X3_TIPO"   , 0 }, { "X3_TAMANHO", 0 }, { "X3_DECIMAL", 0 }, { "X3_TITULO" , 0 }, ;
             { "X3_TITSPA" , 0 }, { "X3_TITENG" , 0 }, { "X3_DESCRIC", 0 }, { "X3_DESCSPA", 0 }, { "X3_DESCENG", 0 }, { "X3_PICTURE", 0 }, { "X3_VALID"  , 0 }, ;
             { "X3_USADO"  , 0 }, { "X3_RELACAO", 0 }, { "X3_F3"     , 0 }, { "X3_NIVEL"  , 0 }, { "X3_RESERV" , 0 }, { "X3_CHECK"  , 0 }, { "X3_TRIGGER", 0 }, ;
             { "X3_PROPRI" , 0 }, { "X3_BROWSE" , 0 }, { "X3_VISUAL" , 0 }, { "X3_CONTEXT", 0 }, { "X3_OBRIGAT", 0 }, { "X3_VLDUSER", 0 }, { "X3_CBOX"   , 0 }, ;
             { "X3_CBOXSPA", 0 }, { "X3_CBOXENG", 0 }, { "X3_PICTVAR", 0 }, { "X3_WHEN"   , 0 }, { "X3_INIBRW" , 0 }, { "X3_GRPSXG" , 0 }, { "X3_FOLDER" , 0 }, ;
             { "X3_CONDSQL", 0 }, { "X3_CHKSQL" , 0 }, { "X3_IDXSRV" , 0 }, { "X3_ORTOGRA", 0 }, { "X3_TELA"   , 0 }, { "X3_POSLGT" , 0 }, { "X3_IDXFLD" , 0 }, ;
             { "X3_AGRUP"  , 0 }, { "X3_MODAL"  , 0 }, { "X3_PYME"   , 0 } }

aEval( aEstrut, { |x| x[2] := SX3->( FieldPos( x[1] ) ) } )


aAdd( aSX3, {'ZZ1','01','ZZ1_FILIAL','C',4,0,'Filial','Sucursal','Branch','Filial do Sistema','Sucursal','Branch of the System','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','033','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ1','02','ZZ1_ENTIDA','C',3,0,'Entidade','Entidade','Entidade','Entidade','Entidade','Entidade','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ1','03','ZZ1_USER','C',6,0,'Usu�rio','Usu�rio','Usu�rio','Usu�rio','Usu�rio','Usu�rio','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ1','04','ZZ1_NOME','C',30,0,'Nome  Usu�ri','Nome  Usu�ri','Nome  Usu�ri','Nome  Usu�rio','Nome  Usu�rio','Nome  Usu�rio','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ1','05','ZZ1_BLQ','C',1,0,'Bloqueado','Bloqueado','Bloqueado','Bloqueado','Bloqueado','Bloqueado','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','S=Sim;N=N�o','S=Sim;N=N�o','S=Sim;N=N�o','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ1','06','ZZ1_DTALT','D',8,0,'Dt. Alt','Dt. Alt','Dt. Alt','Dt. Alt','Dt. Alt','Dt. Alt','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ1','07','ZZ1_HRALT','C',5,0,'Hr. Alt.','Hr. Alt.','Hr. Alt.','Hr. Alt.','Hr. Alt.','Hr. Alt.','99:99','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ1','08','ZZ1_MOTIVO','C',60,0,'Motivo','Motivo','Motivo','Motivo','Motivo','Motivo','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ1','09','ZZ1_USERLG','C',6,0,'Usu�rio Alt.','Usu�rio Alt.','Usu�rio Alt.','Usu�rio Alt.','Usu�rio Alt.','Usu�rio Alt.','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ1','10','ZZ1_NOUSLG','C',30,0,'Nome Usr.  A','Nome Usr.  A','Nome Usr.  A','Nome Usr.  Alt.','Nome Usr.  Alt.','Nome Usr.  Alt.','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ1','11','ZZ1_CPOENT','C',10,0,'Campo Entd.','Campo Entd.','Campo Entd.','Campo Entidade','Campo Entidade','Campo Entidade','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ2','01','ZZ2_FILIAL','C',4,0,'Filial','Sucursal','Branch','Filial do Sistema','Sucursal','Branch of the System','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x','','',0,']xxxxxx x','','','U','S','A','R','x','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ2','02','ZZ2_USER','C',6,0,'Usu�rio','Usu�rio','Usu�rio','Usu�rio','Usu�rio','Usu�rio','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','USRCON',0,'xxxxxx x','','','U','S','A','R','x','UsrExist(M->ZZ2_USER)','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ2','03','ZZ2_NOME','C',30,0,'Nome Usu�rio','Nome Usu�rio','Nome Usu�rio','Nome Usu�rio','Nome Usu�rio','Nome Usu�rio','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ2','04','ZZ2_INCLSR','C',1,0,'Inc Sol Rec?','Inc Sol Rec?','Inc Sol Rec?','Inclui Solic Recurso?','Inclui Solic Recurso?','Inclui Solic Recurso?','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','x','','S=Sim;N=N�o','S=Sim;N=N�o','S=Sim;N=N�o','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ2','05','ZZ2_APRON1','C',1,0,'Aprovador N1','Aprovador N1','Aprovador N1','Aprovador N1','Aprovador N1','Aprovador N1','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','x','Pertence("SN")','S=Sim;N=N�o','S=Sim;N=N�o','S=Sim;N=N�o','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ2','06','ZZ2_APRON2','C',1,0,'Aprovador N2','Aprovador N2','Aprovador N2','Aprovador N2','Aprovador N2','Aprovador N2','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','x','Pertence("SN")','S=Sim;N=N�o','S=Sim;N=N�o','S=Sim;N=N�o','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ2','07','ZZ2_CONCTS','C',1,0,'Contr Ctas?','Contr Ctas?','Contr Ctas?','Controla Contas?','Controla Contas?','Controla Contas?','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','x','Pertence("SN")','S=Sim;N=N�o','S=Sim;N=N�o','S=Sim;N=N�o','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ3','01','ZZ3_FILIAL','C',4,0,'Filial','Sucursal','Branch','Filial do Sistema','Sucursal','Branch of the System','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x','','',1,'XXXXXX X','','','U','N','','','','','','','','','','','033','','','','','','','','','','',''} )
aAdd( aSX3, {'ZZ3','02','ZZ3_USER','C',6,0,'Usu�rio','Usu�rio','Usu�rio','Usu�rio','Usu�rio','Usu�rio','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','USRCON',0,'xxxxxx x','','','U','N','A','R','x','UsrExist(M->ZZ3_USER)','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ3','03','ZZ3_NOME','C',30,0,'Nome Usu�rio','Nome Usu�rio','Nome Usu�rio','Nome Usu�rio','Nome Usu�rio','Nome Usu�rio','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ3','04','ZZ3_TPARPO','C',1,0,'Tipo de  Apr','Tipo de  Apr','Tipo de  Apr','Tipo de  Aprovador','Tipo de  Aprovador','Tipo de  Aprovador','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','x','','1=Aprov.N1;2=Aprov. N2','1=Aprov.N1;2=Aprov. N2','1=Aprov.N1;2=Aprov. N2','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ3','05','ZZ3_APRIME','C',6,0,'Apro Imediat','Apro Imediat','Apro Imediat','Cod Aprovador Imediato','Cod Aprovador Imediato','Aprovador  Imediato','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','USRCON',0,'xxxxxx x','','','U','N','A','R','','UsrExist(M->ZZ2_APRIME)','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ3','06','ZZ3_NMAPIM','C',30,0,'Ap Imediato','Ap Imediato','Ap Imediato','Nome Aprovador Imediato','Nome Aprovador Imediato','Nome Aprovador Imediato','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ3','07','ZZ3_MINIMO','N',16,2,'Limite M�nim','Limite M�nim','Limite M�nim','Limite M�nimo','Limite M�nimo','Limite M�nimo','@E 9,999,999,999,999.99','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','IF(M->ZZ3_MINIMO >= 0 .AND. M->ZZ3_MINIMO <= M->ZZ3_MAXIMO,.T.,.F.)','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ3','08','ZZ3_MAXIMO','N',16,2,'Limite  M�xi','Limite  M�xi','Limite  M�xi','Limite  M�ximo','Limite  M�ximo','Limite  M�ximo','@E 9,999,999,999,999.99','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','x','IF(M->ZZ3_MAXIMO >= M->ZZ3_MINIMO,.T.,.F.)','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ4','01','ZZ4_FILIAL','C',4,0,'Filial','Sucursal','Branch','Filial do Sistema','Sucursal','Branch of the System','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x','','',0,'xxxxxx x','','','U','S','A','R','x','','','','','','','','033','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ4','02','ZZ4_DATADE','D',8,0,'Data Inicial','Data Inicial','Data Inicial','Data Inicial','Data Inicial','Data Inicial','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','x','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ4','03','ZZ4_STATUS','C',1,0,'Status','Status','Status','Status','Status','Status','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','x','','A=Aberto;F=Fechado','A=Aberto;F=Fechado','A=Aberto;F=Fechado','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ5','01','ZZ5_FILIAL','C',4,0,'Filial','Sucursal','Branch','Filial do Sistema','Sucursal','Branch of the System','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','033','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ5','02','ZZ5_DOC','C',14,0,'Documento','Documento','Documento','Documento','Documento','Documento','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ5','03','ZZ5_STATUS','C',1,0,'Status','Status','Status','Status','Status','Status','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','1=Pend Ap N1;2=Pend  Ap N2;3=Pend Ap N3;4=Pend Ap N4;5=Pend Ap N5;6=Rejeitada;7=Aprovada','1=Pend Ap N1;2=Pend  Ap N2;3=Pend Ap N3;4=Pend Ap N4;5=Pend Ap N5;6=Rejeitada;7=Aprovada','1=Pend Ap N1;2=Pend  Ap N2;3=Pend Ap N3;4=Pend Ap N4;5=Pend Ap N5;6=Rejeitada;7=Aprovada','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ5','04','ZZ5_USER','C',6,0,'Usu�rio','Usu�rio','Usu�rio','Usu�rio que inclui  a Sol','Usu�rio que inclui  a Sol','Usu�rio que inclui  a Sol','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ5','05','ZZ5_NUSER','C',30,0,'Nome Usu�rio','Nome Usu�rio','Nome Usu�rio','Usu�rio que inclui  a Sol','Usu�rio que inclui  a Sol','Usu�rio que inclui  a Sol','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ5','06','ZZ5_DATA','D',8,0,'Data','Data','Data','Data da  Solicita��o','Data da  Solicita��o','Data da  Solicita��o','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ5','07','ZZ5_HORA','C',5,0,'Hora','Hora','Hora','Hor�rio da  Solicita��o','Hor�rio da  Solicita��o','Hor�rio da  Solicita��o',' 99:99','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','01','ZZ6_FILIAL','C',4,0,'Filial','Sucursal','Branch','Filial do Sistema','Sucursal','Branch of the System','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','033','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','02','ZZ6_DOC','C',14,0,'Documento','Documento','Documento','Documento','Documento','Documento','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','03','ZZ6_TIPO','C',1,0,'Tipo','Tipo','Tipo','Tipo','Tipo','Tipo','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','D=Debito;C=Cr�dito','Op��es  D=Debito; C =  Cr�dito','Op��es  D=Debito; C =  Cr�dito','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','04','ZZ6_DATA','D',8,0,'Data','Data','Data','Data','Data','Data','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','05','ZZ6_CO','C',12,0,'Conta  Or�am','Conta  Or�am','Conta  Or�am','Conta  Or�ament�ria','Conta  Or�ament�ria','Conta  Or�ament�ria','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','06','ZZ6_CLASSE','C',6,0,'Classe  Or�a','Classe  Or�a','Classe  Or�a','Classe  Or�ament�ria','Classe  Or�ament�ria','Classe  Or�ament�ria','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','AK6',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','07','ZZ6_OPERAC','C',10,0,'Opera��o','Opera��o','Opera��o','Opera��o','Opera��o','Opera��o','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','08','ZZ6_CC','C',20,0,'Centro de  C','Centro de  C','Centro de  C','Centro de  Custo','Centro de  Custo','Centro de  Custo','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','09','ZZ6_ITCTA','C',20,0,'Item Conta','Item Conta','Item Conta','Item Conta','Item Conta','Item Conta','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','10','ZZ6_CLVAL','C',20,0,'Classe de  V','Classe de  V','Classe de  V','Classe de  Valor','Classe de  Valor','Classe de  Valor','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','11','ZZ6_VALOR','N',16,2,'Valor','Valor','Valor','Valor','Valor','Valor','@E 9,999,999,999,999.99','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','12','ZZ6_HIST','C',60,0,'Hist�rico','Hist�rico','Hist�rico','Hist�rico','Hist�rico','Hist�rico','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','13','ZZ6_USRAP1','C',6,0,'Usu�rio Ap.','Usu�rio Ap.','Usu�rio Ap.','Usu�rio Ap.  N1','Usu�rio Ap.  N1','Usu�rio Ap.  N1','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','14','ZZ6_NUSAP1','C',30,0,'Nome  Aprova','Nome  Aprova','Nome  Aprova','Nome  Aprovador N1','Nome  Aprovador N1','Nome  Aprovador N1','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','15','ZZ6_STAT1','C',1,0,'Status Apr.','Status Apr.','Status Apr.','Status Apr.  N1','Status Apr.  N1','Status Apr.  N1','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','P=Pendente;A=Aprovado;R=Rejeitado','Op��es: P =  Pendente;  A=Aprovado; R=  Rejeitado','Op��es: P =  Pendente;  A=Aprovado; R=  Rejeitado','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','16','ZZ6_DTAP1','D',8,0,'Data Apr. N1','Data Apr. N1','Data Apr. N1','Data Apr. N1','Data Apr. N1','Data Apr. N1','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','17','ZZ6_HRAP1','C',5,0,'Hor�rio Apr.','Hor�rio Apr.','Hor�rio Apr.','Hor�rio Apr.  N1','Hor�rio Apr.  N1','Hor�rio Apr.  N1','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','18','ZZ6_USRAP2','C',30,0,'Usu�rio Ap.','Usu�rio Ap.','Usu�rio Ap.','Usu�rio Ap.  N2','Usu�rio Ap.  N2','Usu�rio Ap.  N2','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','19','ZZ6_NUSAP2','C',30,0,'Nome  Aprova','Nome  Aprova','Nome  Aprova','Nome  Aprovador N2','Nome  Aprovador N2','Nome  Aprovador N2','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','20','ZZ6_STAT2','C',1,0,'Status Apr.','Status Apr.','Status Apr.','Status Apr.  N2','Status Apr.  N2','Status Apr.  N2','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','P=Pendente;A=Aprovado;R=Rejeitado','Op��es: P =  Pendente;  A=Aprovado; R=  Rejeitado','Op��es: P =  Pendente;  A=Aprovado; R=  Rejeitado','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','21','ZZ6_DTAP2','D',8,0,'Data Apr. N2','Data Apr. N2','Data Apr. N2','Data Apr. N2','Data Apr. N2','Data Apr. N2','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','22','ZZ6_HRAP2','C',5,0,'Hor�rio Apr.','Hor�rio Apr.','Hor�rio Apr.','Hor�rio Apr.  N2','Hor�rio Apr.  N2','Hor�rio Apr.  N2','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','23','ZZ6_USRCTA','C',30,0,'Usu�rio  Con','Usu�rio  Con','Usu�rio  Con','Usu�rio  Controladoria','Usu�rio  Controladoria','Usu�rio  Controladoria','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','24','ZZ6_NUSCTA','C',30,0,'Nome  Contro','Nome  Contro','Nome  Contro','Nome  Controladoria','Nome  Controladoria','Nome  Controladoria','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','25','ZZ6_STATCT','C',1,0,'Status Apr.','Status Apr.','Status Apr.','Status Apr.  Controladori','Status Apr.  Controladori','Status Apr.  Controladori','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','P=Pendente;A=Aprovado;R=Rejeitado','Op��es: P =  Pendente;  A=Aprovado; R=  Rejeitado','Op��es: P =  Pendente;  A=Aprovado; R=  Rejeitado','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','26','ZZ6_DTCTA','D',8,0,'Data Apr.  C','Data Apr.  C','Data Apr.  C','Data Apr.  Controladoria','Data Apr.  Controladoria','Data Apr.  Controladoria','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZ6','27','ZZ6_HRCTA','C',5,0,'Hor�rio Apr.','Hor�rio Apr.','Hor�rio Apr.','Hor�rio Apr.  Controlador','Hor�rio Apr.  Controlador','Hor�rio Apr.  Controlador','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','V','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZA','01','ZZA_FILIAL','C',4,0,'Filial','Sucursal','Branch','Filial do Sistema','Sucursal','Branch of the System','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x','','',1,'XXXXXX X','','','U','N','','','','','','','','','','','033','','','','','','','','','','',''} )
aAdd( aSX3, {'ZZA','02','ZZA_COD','C',6,0,'C�digo','C�digo','C�digo','C�digo','C�digo','C�digo','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','S','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZA','03','ZZA_DESC','C',30,0,'Descri��o','Descri��o','Descri��o','Descri��o','Descri��o','Descri��o','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZB','01','ZZB_FILIAL','C',4,0,'Filial','Sucursal','Branch','Filial do Sistema','Sucursal','Branch of the System','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x','','',1,'XXXXXX X','','','U','N','','','','','','','','','','','033','','','','','','','','','','',''} )
aAdd( aSX3, {'ZZB','02','ZZB_COD','C',6,0,'C�digo','C�digo','C�digo','C�digo','C�digo','C�digo','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZB','03','ZZB_DESC','C',30,0,'Descri��o','Descri��o','Descri��o','Descri��o','Descri��o','Descri��o','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZC','01','ZZC_FILIAL','C',4,0,'Filial','Sucursal','Branch','Filial do Sistema','Sucursal','Branch of the System','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x','','',1,'XXXXXX X','','','U','N','','','','','','','','','','','033','','','','','','','','','','',''} )
aAdd( aSX3, {'ZZC','02','ZZC_COD','C',6,0,'C�digo','C�digo','C�digo','C�digo','C�digo','C�digo','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZC','03','ZZC_DESC','C',30,0,'Descri��o','Descri��o','Descri��o','Descri��o','Descri��o','Descri��o','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZD','01','ZZD_FILIAL','C',4,0,'Filial','Sucursal','Branch','Filial do Sistema','Sucursal','Branch of the System','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x','','',1,'XXXXXX X','','','U','N','','','','','','','','','','','033','','','','','','','','','','',''} )
aAdd( aSX3, {'ZZD','02','ZZD_COD','C',6,0,'C�digo','C�digo','C�digo','C�digo','C�digo','C�digo','@!','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )
aAdd( aSX3, {'ZZD','03','ZZD_DESC','C',30,0,'Descri��o','Descri��o','Descri��o','Descri��o','Descri��o','Descri��o','','','x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x','','',0,'xxxxxx x','','','U','N','A','R','','','','','','','','','','','','','','N','','','N','','',''} )

//
// Atualizando dicion�rio
//
nPosArq := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ARQUIVO" } )
nPosOrd := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ORDEM"   } )
nPosCpo := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_CAMPO"   } )
nPosTam := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_TAMANHO" } )
nPosSXG := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_GRPSXG"  } )
nPosVld := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_VALID"   } )

aSort( aSX3,,, { |x,y| x[nPosArq]+x[nPosOrd]+x[nPosCpo] < y[nPosArq]+y[nPosOrd]+y[nPosCpo] } )

oProcess:SetRegua2( Len( aSX3 ) )

dbSelectArea( "SX3" )
dbSetOrder( 2 )
cAliasAtu := ""

For nI := 1 To Len( aSX3 )

	//
	// Verifica se o campo faz parte de um grupo e ajusta tamanho
	//
	If !Empty( aSX3[nI][nPosSXG] )
		SXG->( dbSetOrder( 1 ) )
		If SXG->( MSSeek( aSX3[nI][nPosSXG] ) )
			If aSX3[nI][nPosTam] <> SXG->XG_SIZE
				aSX3[nI][nPosTam] := SXG->XG_SIZE
				AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo] + " N�O atualizado e foi mantido em [" + ;
				AllTrim( Str( SXG->XG_SIZE ) ) + "]" + CRLF + ;
				" por pertencer ao grupo de campos [" + SXG->XG_GRUPO + "]" + CRLF )
			EndIf
		EndIf
	EndIf

	SX3->( dbSetOrder( 2 ) )

	If !( aSX3[nI][nPosArq] $ cAlias )
		cAlias += aSX3[nI][nPosArq] + "/"
		aAdd( aArqUpd, aSX3[nI][nPosArq] )
	EndIf

	If !SX3->( dbSeek( PadR( aSX3[nI][nPosCpo], nTamSeek ) ) )

		//
		// Busca ultima ocorrencia do alias
		//
		If ( aSX3[nI][nPosArq] <> cAliasAtu )
			cSeqAtu   := "00"
			cAliasAtu := aSX3[nI][nPosArq]

			dbSetOrder( 1 )
			SX3->( dbSeek( cAliasAtu + "ZZ", .T. ) )
			dbSkip( -1 )

			If ( SX3->X3_ARQUIVO == cAliasAtu )
				cSeqAtu := SX3->X3_ORDEM
			EndIf

			nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
		EndIf

		nSeqAtu++
		cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )

		RecLock( "SX3", .T. )
		For nJ := 1 To Len( aSX3[nI] )
			If     nJ == nPosOrd  // Ordem
				SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), cSeqAtu ) )

			ElseIf aEstrut[nJ][2] > 0
				SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ] ) )

			EndIf
		Next nJ

		dbCommit()
		MsUnLock()

		AutoGrLog( "Criado campo " + aSX3[nI][nPosCpo] )

	EndIf

	oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3)..." )

Next nI

AutoGrLog( CRLF + "Final da Atualiza��o" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSIX
Fun��o de processamento da grava��o do SIX - Indices

@author TOTVS Protheus
@since  11/08/2022
@obs    Gerado por EXPORDIC - V.7.2.0.1 EFS / Upd. V.5.2.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSIX()
Local aEstrut   := {}
Local aSIX      := {}
Local lAlt      := .F.
Local lDelInd   := .F.
Local nI        := 0
Local nJ        := 0

AutoGrLog( "�nicio da Atualiza��o" + " SIX" + CRLF )

aEstrut := { "INDICE" , "ORDEM" , "CHAVE", "DESCRICAO", "DESCSPA"  , ;
             "DESCENG", "PROPRI", "F3"   , "NICKNAME" , "SHOWPESQ" }

aAdd( aSIX, {'ZZ1','1','ZZ1_FILIAL+ZZ1_USER','Usu�rio','Usu�rio','Usu�rio','U','','','S'} )
aAdd( aSIX, {'ZZ2','1','ZZ2_FILIAL+ZZ2_USER','Usu�rio','Usu�rio','Usu�rio','U','','','S'} )
aAdd( aSIX, {'ZZ3','1','ZZ3_FILIAL+ZZ3_USER','Usu�rio','Usu�rio','Usu�rio','U','','','S'} )
aAdd( aSIX, {'ZZ4','1','ZZ4_FILIAL+ZZ4_STATUS+ZZ4_DATADE','Status+Data Inicial','Status+Data Inicial','Status+Data Inicial','U','','','S'} )
aAdd( aSIX, {'ZZ5','1','ZZ5_FILIAL+ZZ5_DOC+ZZ5_USER','Documento+Usu�rio','Documento+Usu�rio','Documento+Usu�rio','U','','','S'} )
aAdd( aSIX, {'ZZ5','2','ZZ5_FILIAL+ZZ5_STATUS','Status','Status','Status','U','','','S'} )
aAdd( aSIX, {'ZZ5','3','ZZ5_FILIAL+ZZ5_USER+ZZ5_DATA','Usu�rio+Data','Usu�rio+Data','Usu�rio+Data','U','','','S'} )
aAdd( aSIX, {'ZZ6','1','ZZ6_FILIAL+ZZ6_DOC','Documento','Documento','Documento','U','','','S'} )
aAdd( aSIX, {'ZZ6','2','ZZ6_FILIAL+ZZ6_TIPO+ZZ6_DATA','Tipo+Data','Tipo+Data','Tipo+Data','U','','','N'} )
aAdd( aSIX, {'ZZ6','3','ZZ6_FILIAL+ZZ6_DOC+ZZ6_TIPO+ZZ6_DATA','Filial+Documento+Tipo+Data','Sucursal+Documento+Tipo+Data','Branch+Documento+Tipo+Data','U','','','S'} )
aAdd( aSIX, {'ZZA','1','ZZA_FILIAL+ZZA_COD+ZZA_DESC','C�digo+Descri��o','C�digo+Descri��o','C�digo+Descri��o','U','','','S'} )
aAdd( aSIX, {'ZZB','1','ZZB_FILIAL+ZZB_COD+ZZB_DESC','C�digo+Descri��o','C�digo+Descri��o','C�digo+Descri��o','U','','','S'} )
aAdd( aSIX, {'ZZC','1','ZZC_FILIAL+ZZC_COD+ZZC_DESC','C�digo+Descri��o','C�digo+Descri��o','C�digo+Descri��o','U','','','S'} )
aAdd( aSIX, {'ZZD','1','ZZD_FILIAL+ZZD_COD+ZZD_DESC','C�digo+Descri��o','C�digo+Descri��o','C�digo+Descri��o','U','','','S'} )
//
// Atualizando dicion�rio
//
oProcess:SetRegua2( Len( aSIX ) )

dbSelectArea( "SIX" )
SIX->( dbSetOrder( 1 ) )

For nI := 1 To Len( aSIX )

	lAlt    := .F.
	lDelInd := .F.

	If !SIX->( dbSeek( aSIX[nI][1] + aSIX[nI][2] ) )
		AutoGrLog( "�ndice criado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
	Else
		lAlt := .T.
		aAdd( aArqUpd, aSIX[nI][1] )
		If !StrTran( Upper( AllTrim( CHAVE )       ), " ", "" ) == ;
		    StrTran( Upper( AllTrim( aSIX[nI][3] ) ), " ", "" )
			AutoGrLog( "Chave do �ndice alterado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
			lDelInd := .T. // Se for altera��o precisa apagar o indice do banco
		EndIf
	EndIf

	RecLock( "SIX", !lAlt )
	For nJ := 1 To Len( aSIX[nI] )
		If FieldPos( aEstrut[nJ] ) > 0
			FieldPut( FieldPos( aEstrut[nJ] ), aSIX[nI][nJ] )
		EndIf
	Next nJ
	MsUnLock()

	dbCommit()

	If lDelInd
		TcInternal( 60, RetSqlName( aSIX[nI][1] ) + "|" + RetSqlName( aSIX[nI][1] ) + aSIX[nI][2] )
	EndIf

	oProcess:IncRegua2( "Atualizando �ndices..." )

Next nI

AutoGrLog( CRLF + "Final da Atualiza��o" + " SIX" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX6
Fun��o de processamento da grava��o do SX6 - Par�metros

@author TOTVS Protheus
@since  11/08/2022
@obs    Gerado por EXPORDIC - V.7.2.0.1 EFS / Upd. V.5.2.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX6()
Local aEstrut   := {}
Local aSX6      := {}
Local cAlias    := ""
Local cMsg      := ""
Local lContinua := .T.
Local lReclock  := .T.
Local lTodosNao := .F.
Local lTodosSim := .F.
Local nI        := 0
Local nJ        := 0
Local nOpcA     := 0
Local nTamFil   := Len( SX6->X6_FIL )
Local nTamVar   := Len( SX6->X6_VAR )

AutoGrLog( "�nicio da Atualiza��o" + " SX6" + CRLF )

aEstrut := { "X6_FIL"    , "X6_VAR"    , "X6_TIPO"   , "X6_DESCRIC", "X6_DSCSPA" , "X6_DSCENG" , "X6_DESC1"  , ;
             "X6_DSCSPA1", "X6_DSCENG1", "X6_DESC2"  , "X6_DSCSPA2", "X6_DSCENG2", "X6_CONTEUD", "X6_CONTSPA", ;
             "X6_CONTENG", "X6_PROPRI" , "X6_VALID"  , "X6_INIT"   , "X6_DEFPOR" , "X6_DEFSPA" , "X6_DEFENG" , ;
             "X6_PYME"   }

aAdd( aSX6, {'  ','FS_GCTCOT','C','Tipo Contrato para cotacao','Tipo Contrato para cotizacion','Contract type for quotation','','','','','','','001','001','001','S','','','001','001','001','S'} )
aAdd( aSX6, {'  ','MV_CTBSER','C','Habilita/Desabilita controle de serializacao por','','','processos Off-Line x On-Line Contabilidade','','','Gerencial.','','','1','1','1','U','','','','','',''} )
aAdd( aSX6, {'  ','MV_CTBSERD','L','Este parametro controla ou nao a exclusao do','','','arquivo de semaforo (_CTBPROC).','','','Os conteudos validos sao: .T. ou .F.','','','.T.','.T.','.T.','U','','','','','',''} )
aAdd( aSX6, {'  ','MV_ENGTPH1','L','Habilita acesso apenas aos usu�rios administradore','','','','','','','','','.T.','.T.','.T.','U','','','','','',''} )
aAdd( aSX6, {'  ','MV_FN370SE','C','','','','','','','','','','1','1','1','U','','','','','',''} )
aAdd( aSX6, {'  ','MV_NGSSWRK','C','Identifica se no modulo de Solicitacao de Servicos','Identifica si en el modulo de Solicitud de Servic.','It identifies if in the Service Request module','ser� utilizado envio de mensagens por workflow','se utilizara envio de mensajes por workflow','the service of messages sent by workflow will be','online aos solicitantes.','on-line a los solicitantes.','used on-line for users.','S','','','U','','','','','',''} )
aAdd( aSX6, {'  ','MV_PROCSP','L','Indica se a manutencao de stored procedures sera','','','realizada por processo. (.T. = Sim / .F. = Nao)','','','','','','.T.','.T.','.T.','U','','','','','',''} )
aAdd( aSX6, {'  ','MV_VCPCCP','N','Qual a data que ser� considerada para','Cu�l es la fecha que se considerader� para','What is the date considered for','a cumulatividade do PCC na Emiss�o.','la acumulaci�n del PCC en la Emisi�n.','PCC cumulativity on Issuance.','1=Emissao, 2=Venc.Real, 3=Dt Contab.','1=Emisi�n, 2=Venc.Real, 3=Fch Contab.','1=Issue, 2=Real Exp., 3=Acc. Date','2','','','U','','','','','',''} )
aAdd( aSX6, {'  ','MV_VCPCCR','N','Qual a data que ser� considerada para','Cu�l es la fecha que se considerader� para','What is the date considered for','a cumulatividade do PCC na Emiss�o.','la acumulaci�n del PCC en la Emisi�n.','PCC cumulativity on Issuance.','1=Emissao, 2=Venc.Real, 3=Dt Contab.','1=Emisi�n, 2=Venc.Real, 3=Fch Contab.','1=Issue, 2=Real Exp., 3=Acc. Date','1','','','U','','','','','',''} )
aAdd( aSX6, {'  ','MV_VL13137','N','Define o valor m�nimo para reten��o do','Define el valor m�nimo para retenci�n de','Defines the minimum withhold value of','Pis/Cofins/Csll de acordo com a Lei 13.137','Pis/Cofins/Csll de acuerdo con la Ley 13.137','Pis/Cofins/Csll according to Law 13,137','','','','10.00','10.00','10.00','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_APRFLUI','L','Habilita ou desabilita a aprova��o de documentos','Habilita ou desabilita a aprova��o de documentos','Habilita ou desabilita a aprova��o de documentos','via Fluig.','via Fluig.','via Fluig.','','','','.T.','.T.','.T.','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_APROVAC','C','Relacao de usuarios que podem aprovar o lancamento','','','de remanejo de recurso','','','','','','000000/000065/000060/000134/000183/000184/','000000/000065/000060/000134/000183/000184/','000000/000065/000060/000134/000183/000184/','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_ARQCERT','C','Arquivo do certificado com o caminho','Arquivo do certificado com o caminho','Arquivo do certificado com o caminho','','','','','','','\certificado\fluig_chain.pem','\certificado\fluig-com.pem','\certificado\fluig-com.pem','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_AVALCC','L','Indica se o Centro de Custo ser� considerado','','','Indica se o Centro de Custo ser� considerado','','','Indica se o Centro de Custo ser� considerado','','','.T.','','','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_AVALCL','L','Indica se a Classe de Valor ser� considerada','','','Indica se a Classe de Valor ser� considerada','','','Indica se a Classe de Valor ser� considerada','','','.T.','','','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_AVALCO','L','Indica se a Conta Or�ament�ria ser� considerada','','','Indica se a Conta Or�ament�ria ser� considerada','','','Indica se a Conta Or�ament�ria ser� considerada','','','.T.','','','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_AVALIT','L','Indica se o Item Cont�bil ser� considerado','','','Indica se o Item Cont�bil ser� considerado','','','Indica se o Item Cont�bil ser� considerado','','','.T.','','','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_CUBOPCO','L','Indica o c�digo do cubo a ser utilizado para consu','','','Indica o c�digo do cubo a ser utilizado para consu','','','Indica o c�digo do cubo a ser utilizado para consu','','','.T.','','','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_FLUIEMP','C','Codigo da empresa para integracao com o FLUIG','Codigo da empresa para integracao com o FLUIG','Codigo da empresa para integracao com o FLUIG','','','','','','','1','99','99','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_FLUIPSW','C','Informe a senha do usuario com privilegio de admin','Informe a senha do usuario com privilegio de admin','Informe a senha do usuario com privilegio de admin','','','','','','','Condominio@135','Condominio@135','Condominio@135','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_FLUUSER','C','Usuario com privilegio de administracao no FLUIG','Usuario com privilegio de administracao no FLUIG','Usuario com privilegio de administracao no FLUIG','','','','','','','atendimento@boavista.com.br','atendimento@boavista.com.br','atendimento@boavista.com.br','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_PLANSU','C','Planilhas que irao somar no valor total do contrat','','','o (impressao)>','','','','','','001|003|004','','','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_PROCSA','C','Indica se o trecho do fonte MT103FIM onde trata a','','','baixa automatica de pre requisicoes sera executada','','','S = executa a personalizacao, N = nao executa','','','S','S','S','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_TMSA','C','TM para baixa de requisicoes automaticas. Utilizad','','','o no PE MT103FIM','','','','','','501','501','501','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_URLFLUI','C','Informe a URL de integracao com o FLUIG','Informe a URL de integracao com o FLUIG','Informe a URL de integracao com o FLUIG','','','','','','','https://boavista.fluig.com','http://boavista.fluig.com','http://boavista.fluig.com','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_USACNK','L','Utiliza documento da tabela CNK?','','','','','','','','','.F.','','','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_USRPCO','C','Usu�rios PCO que tem acesso ao It Ctb','','','02.01.01.0001 - Folha de Pagamento','','','','','','000000;','','000000;','U','','','','','',''} )
aAdd( aSX6, {'  ','ZZ_VERCERT','N','Versao do Protocolo','Versao do Protocolo','Versao do Protocolo','','','','','','','0','0','0','U','','','','','',''} )
aAdd( aSX6, {'0101',' ZZ_AVALCO','C','Indica se a Conta Or�ament�ria ser� considerada','','','','','','','','','','','','U','','','','','',''} )
aAdd( aSX6, {'0101','ZZ_AVALCC','C','Indica se o Centro de Custo ser� considerado','','','','','','','','','','','','U','','','','','',''} )
aAdd( aSX6, {'0101','ZZ_AVALCL','C','Indica se a Classe de Valor ser� considerada','','','','','','','','','','','','U','','','','','',''} )
aAdd( aSX6, {'0101','ZZ_AVALIT','C','Indica se o Item Cont�bil ser� considerado','','','','','','','','','','','','U','','','','','',''} )
aAdd( aSX6, {'0101','ZZ_CUBOPCO','C','Indica o c�digo do cubo a ser utilizado para consu','','','ta de saldos dispon�veis','','','','','','','','','U','','','','','',''} )
aAdd( aSX6, {'0101','ZZ_PCOCTA','C','Define o grupo de conta que devera integrar com','','','Modulo PLanejamento controle orcamentario','','','','','','3;4;5;6;7','3;4;5;6;7','3;4;5;6;7','U','','','','','',''} )
aAdd( aSX6, {'0101','ZZ_PCOF3','C','','','','','','','','','','0012020','','','U','','','','','',''} )
//
// Atualizando dicion�rio
//
oProcess:SetRegua2( Len( aSX6 ) )

dbSelectArea( "SX6" )
dbSetOrder( 1 )

For nI := 1 To Len( aSX6 )
	lContinua := .F.
	lReclock  := .F.

	If !SX6->( dbSeek( PadR( aSX6[nI][1], nTamFil ) + PadR( aSX6[nI][2], nTamVar ) ) )
		lContinua := .T.
		lReclock  := .T.
		AutoGrLog( "Foi inclu�do o par�metro " + aSX6[nI][1] + aSX6[nI][2] + " Conte�do [" + AllTrim( aSX6[nI][13] ) + "]" )
	EndIf

	If lContinua
		If !( aSX6[nI][1] $ cAlias )
			cAlias += aSX6[nI][1] + "/"
		EndIf

		RecLock( "SX6", lReclock )
		For nJ := 1 To Len( aSX6[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSX6[nI][nJ] )
			EndIf
		Next nJ
		dbCommit()
		MsUnLock()
	EndIf

	oProcess:IncRegua2( "Atualizando Arquivos (SX6)..." )

Next nI

AutoGrLog( CRLF + "Final da Atualiza��o" + " SX6" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSXB
Fun��o de processamento da grava��o do SXB - Consultas Padrao

@author TOTVS Protheus
@since  11/08/2022
@obs    Gerado por EXPORDIC - V.7.2.0.1 EFS / Upd. V.5.2.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSXB()
Local aEstrut   := {}
Local aSXB      := {}
Local cAlias    := ""
Local cMsg      := ""
Local lTodosNao := .F.
Local lTodosSim := .F.
Local nI        := 0
Local nJ        := 0
Local nOpcA     := 0

AutoGrLog( "�nicio da Atualiza��o" + " SXB" + CRLF )

aEstrut := { "XB_ALIAS"  , "XB_TIPO"   , "XB_SEQ"    , "XB_COLUNA" , "XB_DESCRI" , "XB_DESCSPA", "XB_DESCENG", ;
             "XB_WCONTEM", "XB_CONTEM" }


aAdd( aSXB, {'ZZ5','1','01','DB','ZZ5','\ZZ5','ZZ5','','ZZ5'} )
aAdd( aSXB, {'ZZ5','2','01','01','Documento+usu�rio','Documento+usu�rio','Documento+usu�rio','',''} )
aAdd( aSXB, {'ZZ5','3','01','01','Cadastra Novo','Incluye Nuevo','Add New','','01'} )
aAdd( aSXB, {'ZZ5','4','01','01','Documento','Sucursal','Branch','','ZZ5_FILIAL+ZZ5_DOC+ZZ5_USER'} )
aAdd( aSXB, {'ZZ5','5','01','','','','','','ZZ5_DOC'} )
aAdd( aSXB, {'ZZ5','5','02','','','','','','ZZ5_USER'} )
//
// Atualizando dicion�rio
//
oProcess:SetRegua2( Len( aSXB ) )

dbSelectArea( "SXB" )
dbSetOrder( 1 )

For nI := 1 To Len( aSXB )

	If !Empty( aSXB[nI][1] )

		If !SXB->( dbSeek( PadR( aSXB[nI][1], Len( SXB->XB_ALIAS ) ) + aSXB[nI][2] + aSXB[nI][3] + aSXB[nI][4] ) )

			If !( aSXB[nI][1] $ cAlias )
				cAlias += aSXB[nI][1] + "/"
				AutoGrLog( "Foi inclu�da a consulta padr�o " + aSXB[nI][1] )
			EndIf

			RecLock( "SXB", .T. )

			For nJ := 1 To Len( aSXB[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					FieldPut( FieldPos( aEstrut[nJ] ), aSXB[nI][nJ] )
				EndIf
			Next nJ

			dbCommit()
			MsUnLock()

		Else

			//
			// Verifica todos os campos
			//
			For nJ := 1 To Len( aSXB[nI] )

				//
				// Se o campo estiver diferente da estrutura
				//
				If !StrTran( AllToChar( SXB->( FieldGet( FieldPos( aEstrut[nJ] ) ) ) ), " ", "" ) == ;
					StrTran( AllToChar( aSXB[nI][nJ] ), " ", "" )

					cMsg := "A consulta padr�o " + aSXB[nI][1] + " est� com o " + SXB->( FieldName( FieldPos( aEstrut[nJ] ) ) ) + ;
					" com o conte�do" + CRLF + ;
					"[" + RTrim( AllToChar( SXB->( FieldGet( FieldPos( aEstrut[nJ] ) ) ) ) ) + "]" + CRLF + ;
					", e este � diferente do conte�do" + CRLF + ;
					"[" + RTrim( AllToChar( aSXB[nI][nJ] ) ) + "]" + CRLF +;
					"Deseja substituir ? "

					If      lTodosSim
						nOpcA := 1
					ElseIf  lTodosNao
						nOpcA := 2
					Else
						nOpcA := Aviso( "ATUALIZA��O DE DICION�RIOS E TABELAS", cMsg, { "Sim", "N�o", "Sim p/Todos", "N�o p/Todos" }, 3, "Diferen�a de conte�do - SXB" )
						lTodosSim := ( nOpcA == 3 )
						lTodosNao := ( nOpcA == 4 )

						If lTodosSim
							nOpcA := 1
							lTodosSim := MsgNoYes( "Foi selecionada a op��o de REALIZAR TODAS altera��es no SXB e N�O MOSTRAR mais a tela de aviso." + CRLF + "Confirma a a��o [Sim p/Todos] ?" )
						EndIf

						If lTodosNao
							nOpcA := 2
							lTodosNao := MsgNoYes( "Foi selecionada a op��o de N�O REALIZAR nenhuma altera��o no SXB que esteja diferente da base e N�O MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta a��o [N�o p/Todos]?" )
						EndIf

					EndIf

					If nOpcA == 1
						RecLock( "SXB", .F. )
						FieldPut( FieldPos( aEstrut[nJ] ), aSXB[nI][nJ] )
						dbCommit()
						MsUnLock()

						If !( aSXB[nI][1] $ cAlias )
							cAlias += aSXB[nI][1] + "/"
							AutoGrLog( "Foi alterada a consulta padr�o " + aSXB[nI][1] )
						EndIf

					EndIf

				EndIf

			Next

		EndIf

	EndIf

	oProcess:IncRegua2( "Atualizando Consultas Padr�es (SXB)..." )

Next nI

AutoGrLog( CRLF + "Final da Atualiza��o" + " SXB" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuHlp
Fun��o de processamento da grava��o dos Helps de Campos

@author TOTVS Protheus
@since  11/08/2022
@obs    Gerado por EXPORDIC - V.7.2.0.1 EFS / Upd. V.5.2.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuHlp()
Local aHlpPor   := {}
Local aHlpEng   := {}
Local aHlpSpa   := {}

AutoGrLog( "�nicio da Atualiza��o" + " " + "Helps de Campos" + CRLF )


oProcess:IncRegua2( "Atualizando Helps de Campos ..." )

aHlpPor := {}
aAdd( aHlpPor, 'Define se o usu�rio inclui solicita��o' )
aAdd( aHlpPor, 'de recurso' )

aHlpEng := {}
aAdd( aHlpEng, 'Define se o usu�rio inclui solicita��o' )
aAdd( aHlpEng, 'de recurso' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Define se o usu�rio inclui solicita��o' )
aAdd( aHlpSpa, 'de recurso' )

PutSX1Help( "PZZ2_INCLSR", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZZ2_INCLSR" )

aHlpPor := {}
aAdd( aHlpPor, 'Define C�digo do Aprovador Imediato do' )
aAdd( aHlpPor, 'usu�rio' )

aHlpEng := {}
aAdd( aHlpEng, 'Define C�digo do Aprovador Imediato do' )
aAdd( aHlpEng, 'usu�rio' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Define C�digo do Aprovador Imediato do' )
aAdd( aHlpSpa, 'usu�rio' )

PutSX1Help( "PZZ3_APRIME", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZZ3_APRIME" )

aHlpPor := {}
aAdd( aHlpPor, 'Nome do Aprovador Imediato do usu�rio' )

aHlpEng := {}
aAdd( aHlpEng, 'Nome do Aprovador Imediato do usu�rio' )

aHlpSpa := {}
aAdd( aHlpSpa, 'Nome do Aprovador Imediato do usu�rio' )

PutSX1Help( "PZZ3_NMAPIM", aHlpPor, aHlpEng, aHlpSpa, .T.,,.T. )
AutoGrLog( "Atualizado o Help do campo " + "ZZ3_NMAPIM" )

AutoGrLog( CRLF + "Final da Atualiza��o" + " " + "Helps de Campos" + CRLF + Replicate( "-", 128 ) + CRLF )

Return {}


//--------------------------------------------------------------------
/*/{Protheus.doc} EscEmpresa
Fun��o gen�rica para escolha de Empresa, montada pelo SM0

@return aRet Vetor contendo as sele��es feitas.
             Se n�o for marcada nenhuma o vetor volta vazio

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function EscEmpresa()

//---------------------------------------------
// Par�metro  nTipo
// 1 - Monta com Todas Empresas/Filiais
// 2 - Monta s� com Empresas
// 3 - Monta s� com Filiais de uma Empresa
//
// Par�metro  aMarcadas
// Vetor com Empresas/Filiais pr� marcadas
//
// Par�metro  cEmpSel
// Empresa que ser� usada para montar sele��o
//---------------------------------------------
Local   aRet      := {}
Local   aSalvAmb  := GetArea()
Local   aSalvSM0  := {}
Local   aVetor    := {}
Local   cMascEmp  := "??"
Local   cVar      := ""
Local   lChk      := .F.
Local   lOk       := .F.
Local   lTeveMarc := .F.
Local   oNo       := LoadBitmap( GetResources(), "LBNO" )
Local   oOk       := LoadBitmap( GetResources(), "LBOK" )
Local   oDlg, oChkMar, oLbx, oMascEmp, oSay
Local   oButDMar, oButInv, oButMarc, oButOk, oButCanc

Local   aMarcadas := {}


If !MyOpenSm0(.F.)
	Return aRet
EndIf


dbSelectArea( "SM0" )
aSalvSM0 := SM0->( GetArea() )
dbSetOrder( 1 )
dbGoTop()

While !SM0->( EOF() )

	If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
		aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
	EndIf

	dbSkip()
End

RestArea( aSalvSM0 )

Define MSDialog  oDlg Title "" From 0, 0 To 280, 395 Pixel

oDlg:cToolTip := "Tela para M�ltiplas Sele��es de Empresas/Filiais"

oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualiza��o"

@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
oLbx:SetArray(  aVetor )
oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
aVetor[oLbx:nAt, 2], ;
aVetor[oLbx:nAt, 4]}}
oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
oLbx:cToolTip   :=  oDlg:cTitle
oLbx:lHScroll   := .F. // NoScroll

@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos" Message "Marca / Desmarca"+ CRLF + "Todos" Size 40, 007 Pixel Of oDlg;
on Click MarcaTodos( lChk, @aVetor, oLbx )

// Marca/Desmarca por mascara
@ 113, 51 Say   oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
@ 112, 80 MSGet oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
Message "M�scara Empresa ( ?? )"  Of oDlg
oSay:cToolTip := oMascEmp:cToolTip

@ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Inverter Sele��o" Of oDlg
oButInv:SetCss( CSSBOTAO )
@ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Marcar usando" + CRLF + "m�scara ( ?? )"    Of oDlg
oButMarc:SetCss( CSSBOTAO )
@ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Desmarcar usando" + CRLF + "m�scara ( ?? )" Of oDlg
oButDMar:SetCss( CSSBOTAO )
@ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), IIf( Len( aRet ) > 0, oDlg:End(), MsgStop( "Ao menos um grupo deve ser selecionado", "UPDEXP" ) ) ) ;
Message "Confirma a sele��o e efetua" + CRLF + "o processamento" Of oDlg
oButOk:SetCss( CSSBOTAO )
@ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
Message "Cancela o processamento" + CRLF + "e abandona a aplica��o" Of oDlg
oButCanc:SetCss( CSSBOTAO )

Activate MSDialog  oDlg Center

RestArea( aSalvAmb )
dbSelectArea( "SM0" )
dbCloseArea()

Return  aRet


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaTodos
Fun��o auxiliar para marcar/desmarcar todos os �tens do ListBox ativo

@param lMarca  Cont�udo para marca .T./.F.
@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaTodos( lMarca, aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := lMarca
Next nI

oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} InvSelecao
Fun��o auxiliar para inverter a sele��o do ListBox ativo

@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function InvSelecao( aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := !aVetor[nI][1]
Next nI

oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} RetSelecao
Fun��o auxiliar que monta o retorno com as sele��es

@param aRet    Array que ter� o retorno das sele��es (� alterado internamente)
@param aVetor  Vetor do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function RetSelecao( aRet, aVetor )
Local  nI    := 0

aRet := {}
For nI := 1 To Len( aVetor )
	If aVetor[nI][1]
		aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
	EndIf
Next nI

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaMas
Fun��o para marcar/desmarcar usando m�scaras

@param oLbx     Objeto do ListBox
@param aVetor   Vetor do ListBox
@param cMascEmp Campo com a m�scara (???)
@param lMarDes  Marca a ser atribu�da .T./.F.

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
Local cPos1 := SubStr( cMascEmp, 1, 1 )
Local cPos2 := SubStr( cMascEmp, 2, 1 )
Local nPos  := oLbx:nAt
Local nZ    := 0

For nZ := 1 To Len( aVetor )
	If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
		If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
			aVetor[nZ][1] := lMarDes
		EndIf
	EndIf
Next

oLbx:nAt := nPos
oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} VerTodos
Fun��o auxiliar para verificar se est�o todos marcados ou n�o

@param aVetor   Vetor do ListBox
@param lChk     Marca do CheckBox do marca todos (referncia)
@param oChkMar  Objeto de CheckBox do marca todos

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function VerTodos( aVetor, lChk, oChkMar )
Local lTTrue := .T.
Local nI     := 0

For nI := 1 To Len( aVetor )
	lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
Next nI

lChk := IIf( lTTrue, .T., .F. )
oChkMar:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0
Fun��o de processamento abertura do SM0 modo exclusivo

@author TOTVS Protheus
@since  11/08/2022
@obs    Gerado por EXPORDIC - V.7.2.0.1 EFS / Upd. V.5.2.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MyOpenSM0(lShared)
Local lOpen := .F.
Local nLoop := 0

If FindFunction( "OpenSM0Excl" )
	For nLoop := 1 To 20
		If OpenSM0Excl(,.F.)
			lOpen := .T.
			Exit
		EndIf
		Sleep( 500 )
	Next nLoop
Else
	For nLoop := 1 To 20
		dbUseArea( .T., , "SIGAMAT.EMP", "SM0", lShared, .F. )

		If !Empty( Select( "SM0" ) )
			lOpen := .T.
			dbSetIndex( "SIGAMAT.IND" )
			Exit
		EndIf
		Sleep( 500 )
	Next nLoop
EndIf

If !lOpen
	MsgStop( "N�o foi poss�vel a abertura da tabela " + ;
	IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATEN��O" )
EndIf

Return lOpen


//--------------------------------------------------------------------
/*/{Protheus.doc} LeLog
Fun��o de leitura do LOG gerado com limitacao de string

@author TOTVS Protheus
@since  11/08/2022
@obs    Gerado por EXPORDIC - V.7.2.0.1 EFS / Upd. V.5.2.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function LeLog()
Local cRet  := ""
Local cFile := NomeAutoLog()
Local cAux  := ""

FT_FUSE( cFile )
FT_FGOTOP()

While !FT_FEOF()

	cAux := FT_FREADLN()

	If Len( cRet ) + Len( cAux ) < 1048000
		cRet += cAux + CRLF
	Else
		cRet += CRLF
		cRet += Replicate( "=" , 128 ) + CRLF
		cRet += "Tamanho de exibi��o maxima do LOG alcan�ado." + CRLF
		cRet += "LOG Completo no arquivo " + cFile + CRLF
		cRet += Replicate( "=" , 128 ) + CRLF
		Exit
	EndIf

	FT_FSKIP()
End

FT_FUSE()

Return cRet


/////////////////////////////////////////////////////////////////////////////
