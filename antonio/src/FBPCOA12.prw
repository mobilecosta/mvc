#include 'totvs.ch'
#Include 'FWMVCDef.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} COMP029_MVC
Tela de consulta MVC

@author Ernani Forastieri e Rodrigo Antonio Godinho
@since 05/10/2009
@version P10
/*/
//-------------------------------------------------------------------
User Function FBPCOA12()
//Local aButtons := {{.F.,Nil},{.F.,Nil},{.F.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,"Salvar"},{.T.,"Cancelar"},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil}}
FWExecView('SOLICITAÇÃO DE RECURSOS - DESTINO',"FBPCOA12", 3,, { || .T. } )//, , ,aButtons )
Return NIL

Static Function ModelDef()
// Cria a estrutura a ser usada no Modelo de Dados
Local oStruPar := FWFormModelStruct():New()
Local oStruZZ5 := FWFormStruct( 1, 'ZZ5' , { |x| ALLTRIM(x) $ 'ZZ5_FILIAL, ZZ5_DOC, ZZ5_STATUS, ZZ5_USER, ZZ5_NUSER, ZZ5_DATA, ZZ5_HORA'        } )
Local oStruZZ6 := FWFormStruct( 1, 'ZZ6' , { |x| ALLTRIM(x) $ 'ZZ6_FILIAL,ZZ6_DOC,ZZ6_TIPO,ZZ6_DATA,ZZ6_CO,ZZ6_CLASSE,ZZ6_OPERAC,ZZ6_CC,ZZ6_ITCTA,ZZ6_CLVAL,ZZ6_VALOR,ZZ6_HIST,ZZ6_USRAP1,ZZ6_NUSAP1,ZZ6_STAT1,ZZ6_DTAP1,ZZ6_HRAP1, ZZ6_USRAP2,ZZ6_NUSAP2,ZZ6_STAT2,ZZ6_DTAP2,ZZ6_HRAP2,ZZ6_USRCTA,ZZ6_NUSCTA,ZZ6_STATCT,ZZ6_DTCTA,ZZ6_HRCTA' } )
Local oStruZZ62 := FWFormStruct( 1, 'ZZ6' , { |x| ALLTRIM(x) $ 'ZZ6_FILIAL,ZZ6_DOC,ZZ6_TIPO,ZZ6_DATA,ZZ6_CO,ZZ6_CLASSE,ZZ6_OPERAC,ZZ6_CC,ZZ6_ITCTA,ZZ6_CLVAL,ZZ6_VALOR,ZZ6_HIST,ZZ6_USRAP1,ZZ6_NUSAP1,ZZ6_STAT1,ZZ6_DTAP1,ZZ6_HRAP1, ZZ6_USRAP2,ZZ6_NUSAP2,ZZ6_STAT2,ZZ6_DTAP2,ZZ6_HRAP2,ZZ6_USRCTA,ZZ6_NUSCTA,ZZ6_STATCT,ZZ6_DTCTA,ZZ6_HRCTA' } )
//Local oModel
Local cIdPonto := ""
Local cIdModel := ""

Local oModel   := MPFormModel():New('FBPCOA12', , { |oModel| fSave(oModel) })

oStruPar:AddField( ;
"Origem"                       , ;               // [01] Titulo do campo
"Origem"                       , ;               // [02] ToolTip do campo
'BOTAO1'                        , ;               // [03] Id do Field
'BT'                           , ;               // [04] Tipo do campo
1                              , ;               // [05] Tamanho do campo
0                              , ;               // [06] Decimal do campo
{ |oMdl| Origem( oMdl ), .T. }  )               // [07] Code-block de validação do campo

oStruPar:AddField( ;
"Destino"                     , ;               // [01] Titulo do campo
"Destino"                     , ;               // [02] ToolTip do campo
'BOTAO2'                        , ;               // [03] Id do Field
'BT'                           , ;               // [04] Tipo do campo
1                              , ;               // [05] Tamanho do campo
0                              , ;               // [06] Decimal do campo
{ |oMdl| Destino( oMdl ), .T. }  )               // [07] Code-block de validação do campo


oStruZZ5:SetProperty ( 'ZZ5_DOC', MODEL_FIELD_VALID, FWBuildFeature( 1, '.T.' ) )
oStruZZ5:SetProperty ( 'ZZ5_DOC', MODEL_FIELD_INIT , NIL )

oModel := MPFormModel():New( 'DESTINO' , , { | oMdl | NIL } )

oModel:AddFields( 'PARAMETROS', NIL, oStruPar )

oModel:AddGrid( 'ZZ5DETAIL', 'PARAMETROS', oStruZZ5 )
oModel:AddGrid( 'ZZ6DETAIL', 'ZZ5DETAIL', oStruZZ6 )
oModel:AddGrid( 'ZZ62DETAIL', 'ZZ6DETAIL', oStruZZ62 )

oModel:GetModel('ZZ6DETAIL'):SetMaxLine( GetNewPar("MV_COMLMAX", 99) )

//oModel:AddCalc( 'CALCULOS', 'PARAMETROS', 'ZZ5DETAIL', 'ZZ5_DOC', 'ZZ5__TOT01', 'COUNT', { | oFW | TOTAIS( oFW, .T. ) }, , "TOTAL 01" )
//oModel:AddCalc( 'CALCULOS', 'PARAMETROS', 'ZZ5DETAIL', 'ZZ5_DOC', 'ZZ5__TOT02', 'COUNT', { | oFW | TOTAIS( oFW, .F. ) }, , "TOTAL 02" )

//oModel:SetRelation( 'ZZ5DETAIL', { { 'ZZ5_FILIAL', 'xFilial( "ZZ5" )' } , { 'ZZ6_DOC', 'ZZ5_DOC' } } , ZZ5->( IndexKey( 1 ) ) )
oModel:SetRelation( 'ZZ6DETAIL', { { 'ZZ6_FILIAL', 'xFilial( "ZZ6" )' } , { 'ZZ6_DOC', 'ZZ5_DOC' } } , ZZ6->( IndexKey( 1 ) ) )
oModel:SetRelation( 'ZZ62DETAIL', { { 'ZZ6_FILIAL', 'xFilial( "ZZ6" )' } , { 'ZZ6_DOC', 'ZZ5_DOC' } } , ZZ6->( IndexKey( 1 ) ) )

oModel:GetModel( 'ZZ62DETAIL' ):SetUniqueLine( { 'ZZ6_DOC' } )

oModel:SetDescription( 'TIPO DE SOLICITAÇÃO - DESTINO' )
oModel:GetModel( 'PARAMETROS' ):SetDescription( 'PARAMETROS' )
oModel:GetModel( 'ZZ5DETAIL' ):SetDescription( 'DESTINO' )
oModel:GetModel( 'ZZ6DETAIL' ):SetDescription( 'DADOS DO DESTINO'  )
oModel:GetModel( 'ZZ62DETAIL' ):SetDescription( 'DADOS DA ORIGEM'  )

oModel:SetPrimaryKey( {} )

If cIdPonto == 'FORMPOS'
    Help(NIL, NIL, "HELP", NIL, "Informe a data", 1, 0, NIL, NIL, NIL, NIL, NIL, {"MENSAGEM"})
    xRet := .F.
Endif

Return oModel


//-------------------------------------------------------------------
Static Function ViewDef()
// Cria a estrutura a ser usada na View
Local oStruPar := FWFormViewStruct():New()
//Local oStruZZ5 := FWFormStruct( 2, 'ZZ5' , { |x| ALLTRIM(x) $ 'ZZ5_FILIAL, ZZ5_DOC' } )
//Local oStruZZ6 := FWFormStruct( 2, 'ZZ6' , { |x| ALLTRIM(x) $ 'ZZ5_FILIAL, ZZ6_DOC, ZZ6_TIPO' } )
Local oStruZZ5 := FWFormStruct( 2, 'ZZ5' , { |x| ALLTRIM(x) $ 'ZZ5_FILIAL, ZZ5_DOC, ZZ5_STATUS, ZZ5_USER, ZZ5_NUSER, ZZ5_DATA, ZZ5_HORA'        } )
Local oStruZZ6 := FWFormStruct( 2, 'ZZ6' , { |x| ALLTRIM(x) $ 'ZZ6_FILIAL,ZZ6_DOC,ZZ6_TIPO,ZZ6_DATA,ZZ6_CO,ZZ6_CLASSE,ZZ6_OPERAC,ZZ6_CC,ZZ6_ITCTA,ZZ6_CLVAL,ZZ6_VALOR,ZZ6_HIST,ZZ6_USRAP1,ZZ6_NUSAP1,ZZ6_STAT1,ZZ6_DTAP1,ZZ6_HRAP1, ZZ6_USRAP2,ZZ6_NUSAP2,ZZ6_STAT2,ZZ6_DTAP2,ZZ6_HRAP2,ZZ6_USRCTA,ZZ6_NUSCTA,ZZ6_STATCT,ZZ6_DTCTA,ZZ6_HRCTA' } )
Local oStruZZ62 := FWFormStruct( 2, 'ZZ6' , { |x| ALLTRIM(x) $ 'ZZ6_FILIAL,ZZ6_DOC,ZZ6_TIPO,ZZ6_DATA,ZZ6_CO,ZZ6_CLASSE,ZZ6_OPERAC,ZZ6_CC,ZZ6_ITCTA,ZZ6_CLVAL,ZZ6_VALOR,ZZ6_HIST,ZZ6_USRAP1,ZZ6_NUSAP1,ZZ6_STAT1,ZZ6_DTAP1,ZZ6_HRAP1, ZZ6_USRAP2,ZZ6_NUSAP2,ZZ6_STAT2,ZZ6_DTAP2,ZZ6_HRAP2,ZZ6_USRCTA,ZZ6_NUSCTA,ZZ6_STATCT,ZZ6_DTCTA,ZZ6_HRCTA' } )

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel   := FWLoadModel( 'FBPCOA12' )
Local oView
//Local oCalc1

oStruPar:AddField( ;
'BOTAO1'          , ;             // [01] Campo
"ZZ"             , ;             // [02] Ordem
"Origem"       , ;             // [03] Titulo
"Origem"       , ;             // [04] Descricao
NIL              , ;             // [05] Help
'BT'             )               // [06] Tipo do campo   COMBO, Get ou CHECK

oStruPar:AddField( ;
'BOTAO2'          , ;             // [01] Campo
"ZZ"             , ;             // [02] Ordem
"Destino"       , ;             // [03] Titulo
"Destno"       , ;             // [04] Descricao
NIL              , ;             // [05] Help
'BT'             )               // [06] Tipo do campo   COMBO, Get ou CHECK

oView := FWFormView():New()
oView:SetModel( oModel )
oView:AddField( 'VIEW_PAR' , oStruPar, 'PARAMETROS'   )
oView:AddGrid(  'VIEW_ZZ5' , oStruZZ5, 'ZZ5DETAIL'    )
oView:AddGrid(  'VIEW_ZZ6' , oStruZZ6, 'ZZ6DETAIL'    )
oView:AddGrid(  'VIEW_ZZ62' , oStruZZ62, 'ZZ62DETAIL'    )

//oCalc1 := FWCalcStruct( oModel:GetModel( 'CALCULOS') )
//oView:AddField( 'VIEW_CALC', oCalc1, 'CALCULOS' )

oView:CreateHorizontalBox( "BOX1",  00)
oView:CreateHorizontalBox( "BOX2",  15 )
oView:CreateHorizontalBox( "BOX3",  65 )
oView:CreateHorizontalBox( "BOX4",  20 )

oView:SetOwnerView( 'VIEW_PAR' , "BOX1" )
oView:SetOwnerView( 'VIEW_ZZ5' , "BOX2" )
//oView:SetOwnerView( 'VIEW_CALC', "BOX3" )
oView:SetOwnerView( 'VIEW_ZZ6' , "BOX3" )
oView:SetOwnerView( 'VIEW_ZZ62' , "BOX4" )

//oView:EnableTitleView('VIEW_CALC','TOTAIS')

Return oView

//-------------------------------------------------------------------
Static Function Origem( oMdl )
Local aArea      := GetArea()
Local cOrigem    := ''
Local cTmp       := GetNextAlias()
Local cTmp2      := GetNextAlias()
Local nLinhaZZ5  := 0
Local nLinhaZZ6  := 0
Local oModel     := FWModelActive()
Local oModelZZ5  := oModel:GetModel( 'ZZ5DETAIL' )
Local oModelZZ6  := oModel:GetModel( 'ZZ6DETAIL' )

cOrigem := M->ZZ5_DOC // oModel:GetValue( 'PARAMETROS', 'BOTAO1' )

BeginSql Alias cTmp
	
	SELECT ZZ5_FILIAL, ZZ5_DOC, ZZ6_FILIAL, ZZ6_DOC, ZZ6_TIPO
	FROM %table:ZZ5% ZZ5, %table:ZZ6% ZZ6
	WHERE ZZ5_FILIAL = %xFilial:ZZ5%
	AND ZZ6_FILIAL = %xFilial:ZZ6%
/*	AND ZZ5_DOC = %Exp:cOrigem%
	AND ZZ6_DOC = ZZ5_DOC
	AND ZZ5.%NotDel%
	AND ZZ6.%NotDel%
*/
EndSql

nLinhaZZ5 := 1

While !(cTmp)->( EOF() )
/*	
	If nLinhaZZ5 > 1
		If oModelZZ5:AddLine() <> nLinhaZZ5
			Help( ,, 'HELP',, 'Nao incluiu linha ZZ5' + CRLF + oModel:getErrorMessage()[6], 1, 0)   
			(cTmp)->( dbSkip() )
			Loop			
		EndIf
	EndIf
*/	
	oModelZZ5:SetValue( 'ZZ5_FILIAL',(cTmp)->ZZ5_FILIAL )
	oModelZZ5:SetValue( 'ZZ5_DOC',(cTmp)->ZZ5_DOC )
	
	nLinhaZZ5++
	
	cOrigem := (cTmp)->ZZ5_DOC
	
	BeginSql Alias cTmp2
		
		SELECT ZZ6_FILIAL, ZZ6_DOC, ZZ6_TIPO, *
		
		FROM %table:ZZ6% ZZ6
		
		WHERE ZZ6_FILIAL = %xFilial:ZZ6%
		AND ZZ6_TIPO = "D"
		AND ZZ6.%NotDel%
		
	EndSql
	
	
	nLinhaZZ6 := 1
	
	While !(cTmp2)->( EOF() )  .AND. 	cOrigem== (cTmp2)->ZZ6_FILIAL   
	/*	
		If nLinhaZZ6 > 1
			If oModelZZ6:AddLine() <> nLinhaZZ6
				Help( ,, 'HELP',, 'Nao incluiu linha ZZ6' + CRLF + oModel:getErrorMessage()[6], 1, 0)
				(cTmp2)->( dbSkip() )
				Loop
			EndIf
		EndIf
	*/	
		oModelZZ6:SetValue( 'ZZ6_FILIAL',(cTmp2)->ZZ6_FILIAL )
		oModelZZ6:SetValue( 'ZZ6_DOC', (cTmp2)->ZZ6_DOC )
		oModelZZ6:SetValue( 'ZZ6_TIPO', (cTmp2)->ZZ6_TIPO )
		oModelZZ6:SetValue( 'ZZ6_DATA', (cTmp2)->ZZ6_DATA )
		oModelZZ6:SetValue( 'ZZ6_CO', (cTmp2)->ZZ6_CO )
		oModelZZ6:SetValue( 'ZZ6_CLASSE', (cTmp2)->ZZ6_CLASSE )
		oModelZZ6:SetValue( 'ZZ6_OPERAC', (cTmp2)->ZZ6_OPERAC )
		oModelZZ6:SetValue( 'ZZ6_CC', (cTmp2)->ZZ6_CC )
		oModelZZ6:SetValue( 'ZZ6_ITCTA', (cTmp2)->ZZ6_ITCTA )
		oModelZZ6:SetValue( 'ZZ6_CLVAL', (cTmp2)->ZZ6_CLVAL )
		oModelZZ6:SetValue( 'ZZ6_VALOR', (cTmp2)->ZZ6_VALOR )
		oModelZZ6:SetValue( 'ZZ6_HIST', (cTmp2)->ZZ6_HIST )
		oModelZZ6:SetValue( 'ZZ6_USRAP1', (cTmp2)->ZZ6_USRAP1 )
		oModelZZ6:SetValue( 'ZZ6_NUSAP1', (cTmp2)->ZZ6_NUSAP1 )
		oModelZZ6:SetValue( 'ZZ6_STAT1', (cTmp2)->ZZ6_STAT1 )
		oModelZZ6:SetValue( 'ZZ6_DTAP1', (cTmp2)->ZZ6_DTAP1 )
		oModelZZ6:SetValue( 'ZZ6_HRAP1', (cTmp2)->ZZ6_HRAP1 )
		oModelZZ6:SetValue( 'ZZ6_USRAP2', (cTmp2)->ZZ6_USRAP2 )
		oModelZZ6:SetValue( 'ZZ6_NUSAP2', (cTmp2)->ZZ6_NUSAP2 )
		oModelZZ6:SetValue( 'ZZ6_STAT2', (cTmp2)->ZZ6_STAT2 )
		oModelZZ6:SetValue( 'ZZ6_DTAP2', (cTmp2)->ZZ6_DTAP2 )
		oModelZZ6:SetValue( 'ZZ6_HRAP2', (cTmp2)->ZZ6_HRAP2 )
		oModelZZ6:SetValue( 'ZZ6_USRCTA', (cTmp2)->ZZ6_USRCTA )
		oModelZZ6:SetValue( 'ZZ6_NUSCTA', (cTmp2)->ZZ6_NUSCTA )
		oModelZZ6:SetValue( 'ZZ6_STATCT', (cTmp2)->ZZ6_STATCT )
		oModelZZ6:SetValue( 'ZZ6_DTCTA', (cTmp2)->ZZ6_DTCTA )
		oModelZZ6:SetValue( 'ZZ6_HRCTA', (cTmp2)->ZZ6_HRCTA )

		nLinhaZZ6++
		
		(cTmp2)->( dbSkip() )
	End
	
	(cTmp2)->( dbCloseArea() )
	
	(cTmp)->( dbSkip() )
End

(cTmp)->( dbCloseArea() )

RestArea( aArea )

Return NIL



//-------------------------------------------------------------------
Static Function Destino( oMdl )
Local aArea      := GetArea()
Local cOrigem    := ''
Local cTmp       := GetNextAlias()
Local cTmp2      := GetNextAlias()
Local nLinhaZZ5  := 0
Local nLinhaZZ6  := 0
Local oModel     := FWModelActive()
Local oModelZZ5  := oModel:GetModel( 'ZZ5DETAIL' )
Local oModelZZ6  := oModel:GetModel( 'ZZ6DETAIL' )

cOrigem := M->ZZ6_DOC //oModel:GetValue( 'PARAMETROS', 'BOTAO2' )

oModelZZ5:DeActivate( .T. )
If !oModelZZ5:Activate()
	Help( ,, 'Help',, 'Restricao de ativacao do Modelo Destino', 1, 0 )
	Return NIL
EndIf	

BeginSql Alias cTmp
	
	SELECT ZZ5_FILIAL, ZZ5_DOC, ZZ6_FILIAL, ZZ6_DOC, ZZ6_TIPO
	FROM %table:ZZ5% ZZ5, %table:ZZ6% ZZ6
	WHERE ZZ5_FILIAL = %xFilial:ZZ5%
	AND ZZ6_FILIAL = %xFilial:ZZ6%
	AND ZZ5_DOC = %Exp:cOrigem%
	AND ZZ6_DOC = ZZ5_DOC
	AND ZZ5.%NotDel%
	AND ZZ6.%NotDel%
	
EndSql

nLinhaZZ5 := 1

While !(cTmp)->( EOF() )
	
	If nLinhaZZ5 > 1
		If oModelZZ5:AddLine() <> nLinhaZZ5
			Help( ,, 'HELP',, 'Nao incluiu linha ZZ5 - destino' + CRLF + oModel:getErrorMessage()[6], 1, 0)   
			(cTmp)->( dbSkip() )
			Loop			
		EndIf
	EndIf

	oModelZZ5:SetValue( 'ZZ5_FILIAL',(cTmp)->ZZ5_FILIAL )
	oModelZZ5:SetValue( 'ZZ5_DOC',(cTmp)->ZZ5_DOC )

	nLinhaZZ5++
	
	cOrigem := (cTmp)->ZZ5_DOC
	
	BeginSql Alias cTmp2
		
		SELECT ZZ6_FILIAL, ZZ6_DOC, ZZ6_TIPO, *
		
		FROM %table:ZZ6% ZZ6
		
		WHERE ZZ6_FILIAL = %xFilial:ZZ6%
		AND ZZ6_TIPO = "C"
		AND ZZ6.%NotDel%
		
	EndSql
	
	
	nLinhaZZ6 := 1
	
	While !(cTmp2)->( EOF() )  .AND. 	cOrigem== (cTmp2)->ZZ6_FILIAL   
		
		If nLinhaZZ6 > 1
			If oModelZZ6:AddLine() <> nLinhaZZ6
				Help( ,, 'HELP',, 'Nao incluiu linha ZZ6 - destino' + CRLF + oModel:getErrorMessage()[6], 1, 0)
				(cTmp2)->( dbSkip() )
				Loop
			EndIf
		EndIf
		
			
		oModelZZ6:SetValue( 'ZZ6_FILIAL',(cTmp2)->ZZ6_FILIAL )
		oModelZZ6:SetValue( 'ZZ6_DOC', (cTmp2)->ZZ6_DOC )
		oModelZZ6:SetValue( 'ZZ6_TIPO', (cTmp2)->ZZ6_TIPO )
		oModelZZ6:SetValue( 'ZZ6_DATA', (cTmp2)->ZZ6_DATA )
		oModelZZ6:SetValue( 'ZZ6_CO', (cTmp2)->ZZ6_CO )
		oModelZZ6:SetValue( 'ZZ6_CLASSE', (cTmp2)->ZZ6_CLASSE )
		oModelZZ6:SetValue( 'ZZ6_OPERAC', (cTmp2)->ZZ6_OPERAC )
		oModelZZ6:SetValue( 'ZZ6_CC', (cTmp2)->ZZ6_CC )
		oModelZZ6:SetValue( 'ZZ6_ITCTA', (cTmp2)->ZZ6_ITCTA )
		oModelZZ6:SetValue( 'ZZ6_CLVAL', (cTmp2)->ZZ6_CLVAL )
		oModelZZ6:SetValue( 'ZZ6_VALOR', (cTmp2)->ZZ6_VALOR )
		oModelZZ6:SetValue( 'ZZ6_HIST', (cTmp2)->ZZ6_HIST )
		oModelZZ6:SetValue( 'ZZ6_USRAP1', (cTmp2)->ZZ6_USRAP1 )
		oModelZZ6:SetValue( 'ZZ6_NUSAP1', (cTmp2)->ZZ6_NUSAP1 )
		oModelZZ6:SetValue( 'ZZ6_STAT1', (cTmp2)->ZZ6_STAT1 )
		oModelZZ6:SetValue( 'ZZ6_DTAP1', (cTmp2)->ZZ6_DTAP1 )
		oModelZZ6:SetValue( 'ZZ6_HRAP1', (cTmp2)->ZZ6_HRAP1 )
		oModelZZ6:SetValue( 'ZZ6_USRAP2', (cTmp2)->ZZ6_USRAP2 )
		oModelZZ6:SetValue( 'ZZ6_NUSAP2', (cTmp2)->ZZ6_NUSAP2 )
		oModelZZ6:SetValue( 'ZZ6_STAT2', (cTmp2)->ZZ6_STAT2 )
		oModelZZ6:SetValue( 'ZZ6_DTAP2', (cTmp2)->ZZ6_DTAP2 )
		oModelZZ6:SetValue( 'ZZ6_HRAP2', (cTmp2)->ZZ6_HRAP2 )
		oModelZZ6:SetValue( 'ZZ6_USRCTA', (cTmp2)->ZZ6_USRCTA )
		oModelZZ6:SetValue( 'ZZ6_NUSCTA', (cTmp2)->ZZ6_NUSCTA )
		oModelZZ6:SetValue( 'ZZ6_STATCT', (cTmp2)->ZZ6_STATCT )
		oModelZZ6:SetValue( 'ZZ6_DTCTA', (cTmp2)->ZZ6_DTCTA )
		oModelZZ6:SetValue( 'ZZ6_HRCTA', (cTmp2)->ZZ6_HRCTA )
		
		nLinhaZZ6++
		
		(cTmp2)->( dbSkip() )
	End
	
	(cTmp2)->( dbCloseArea() )
	
	(cTmp)->( dbSkip() )
End

(cTmp)->( dbCloseArea() )

RestArea( aArea )

Return NIL



/*/{Protheus.doc} FBPCOA11
Browse - Itens Solicitação de Recurso

@type User Function
@author Antonio Nunes
@since 28/06/2022
@version 12.1.027
@return   
/*/
/*
user function FBPCOA11()
    Local aArea         := GetArea()

    DbSelectArea(AKX)
    DbSetOrder(1)

    If DbSeek(fwxFilial("AKX") + AKX->AKX_USER )
        If AKX->AKX_ZZBLQ = "S" 
            DbSetField(AKX, "AKX_ZZDTBLQ", dDatabase)
            DbSetField(AKX, "AKX_ZZHRLG", time())
            DbSetField(AKX, "AKX_ZZUSER", retCodUsr())
            DbSetField(AKX, "AKX_ZZNMUS", retNomeUsr())
        End If
    EndIf
    
    RestArea(aArea)
    
Return
*/

static function FBPCOA12POS()
return ({|| .t.})




User Function GatZZ6()
Local lRet := .T.
Local oModel := FWModelActive()
Local cDesc := oModel:GetValue('ZZ5MASTER','ZZ5_DOC')

oModel:SetValue('ZZ6MASTER','ZZ6_DOC',cDesc)

Return lRet


Static Function fSave(oModel)
Local lRet := .T.
Local nOpc := oModel:GetOperation()

      lRet := FwFormCommit(oModel)

      If(nOpc == MODEL_OPERATION_INSERT) .and. (lRet)

         //If(lRet .and. ZXR->ZXR_STATUS == '2')

            RecLock('ZZ5',.T.)
               ZZ5->ZZ5_FILIAL  := M->ZZ5_FILIAL
               ZZ5->ZZ5_DOC 	:= M->ZZ5_USER
			   ZZ5->ZZ5_DOC		:= M->ZZ5_NUSER
			   ZZ5->ZZ5_DOC 	:= M->ZZ5_DATA
			   ZZ5->ZZ5_DOC 	:= M->ZZ5_HORA
            ZZ5->(MsUnlock())

            RecLock('ZZ6',.T.)
               ZZ6->ZZ6_FILIAL  := M-ZZ6_FILIAL
               ZZ6->ZZ6_DOC 	:= M->ZZ6_DOC
			   ZZ6->ZZ6_TIPO	:= M->ZZ6_TIPO
			   ZZ6->ZZ6_DATA 	:= M->ZZ6_DATA
			   ZZ6->ZZ6_CLASSE 	:= M->ZZ6_CLASSE
			   ZZ6->ZZ6_CO		:= M->ZZ6_CO
            ZZ6->(MsUnlock())


         //Endif

      Endif

Return(lRet)
