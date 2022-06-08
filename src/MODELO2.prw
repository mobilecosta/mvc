#INCLUDE 'TCRMA006.CH'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE "APWIZARD.CH"

/*/{Protheus.doc} TCRMA006
(Cadastro de Tabelas Gen�ricas - TDI) - ID CRM1044

@author Anderson Alberto
@since 19/05/2015
@version 1.0
/*/ 

User Function TCRMA006() 

//��������������������������������������������������������������Ŀ
//� Declaracao de variaveis                                      �
//����������������������������������������������������������������
Local aArea		:= GetArea()
Local oBrowse	:= Nil 

//��������������������������������������������������������������Ŀ
//� Cria Objeto Browse                                           �
//����������������������������������������������������������������
oBrowse:= FWMBrowse():New()
oBrowse:SetAlias('ZX5')
oBrowse:SetDescription(STR0001)	// 'Solicita��o Cadastro de Tabelas Gen�ricas - TDI'
oBrowse:SetFilterDefault("Empty(ZX5_CHAVE).and.Empty(ZX5_CHAVE2)")

oBrowse:Activate()
 
Return(aArea)

/*/{Protheus.doc} MenuDef

(Op��es do menu)

@author Anderson Alberto Alberto
@since 19/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

Static Function MenuDef()

//��������������������������������������������������������������Ŀ
//� Declaracao de variaveis                                      �
//����������������������������������������������������������������
Local aRotina	:= {}

//��������������������������������������������������������������Ŀ
//� Op��es para o usuarios                                       �
//����������������������������������������������������������������
ADD	OPTION	aRotina	TITLE	STR0002	ACTION	'PesqBrw'			OPERATION 1 ACCESS 0	// 'Pesquisar'
ADD	OPTION	aRotina	TITLE	STR0003	ACTION	'VIEWDEF.TCRMA006'	OPERATION 2 ACCESS 0	// 'Visualizar'
ADD	OPTION	aRotina	TITLE	STR0004	ACTION	'VIEWDEF.TCRMA006'	OPERATION 3 ACCESS 0	// 'Incluir'
ADD	OPTION	aRotina	TITLE	STR0005	ACTION	'VIEWDEF.TCRMA006'	OPERATION 4 ACCESS 0	// 'Alterar'

Return(aRotina)

/*/{Protheus.doc} ModelDef

(Regra de Negocio)

@author Anderson Alberto
@since 19/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

Static Function ModelDef()  

//��������������������������������������������������������������Ŀ
//� Declaracao de variaveis                                      �
//����������������������������������������������������������������
Local oStruZX5		:= FWFormStruct(1,'ZX5',{|cCampo| AllTrim(cCampo) $ "ZX5_TABELA|ZX5_DESCRI|ZX5_DESENG|ZX5_DESESP"})
Local oStruZX52		:= FWFormStruct(1,'ZX5', /*lViewUsado*/)
Local oModel		:= Nil
Local bLoadItens	:= {|oModelX,nX| TA06Load(1,oModelX,nX,ZX5->ZX5_TABELA)}

//��������������������������������������������������������������Ŀ
//� Cria o objeto do Modelo de Dados				             �
//����������������������������������������������������������������
oModel := MPFormModel():New('MODELZX5', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )
oModel:AddFields('DADOSZX5'	, /*cOwner*/, oStruZX5, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )
oModel:AddGrid('DADOSZX52'	,'DADOSZX5'	, oStruZX52,,,,,bLoadItens)
oModel:SetDescription(STR0008)													// Dados Solicita��o Cadastro de Tabelas Gen�ricas - TDI
oModel:SetPrimaryKey({"ZX5_FILIAL", "ZX5_TABELA", "ZX5_CHAVE", "ZX5_CHAVE2"})
oModel:GetModel('DADOSZX52'):SetUniqueLine({ 'ZX5_CHAVE', 'ZX5_CHAVE2' })
oModel:GetModel('DADOSZX5'):SetDescription(STR0009)								// 'Cadastro de Tabelas Gen�ricas'
oModel:GetModel('DADOSZX52'):SetDescription(STR0010)							// 'Itens Tabelas Gen�ricas'
oModel:SetRelation('DADOSZX52',{{'ZX5_FILIAL','xFilial("ZX5")'},{'ZX5_TABELA','ZX5_TABELA'}},ZX5->(IndexKey(1)))  

Return(oModel)

/*/{Protheus.doc} ViewDef

(Interface)

@author Anderson Alberto
@since 19/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

Static Function ViewDef()

//��������������������������������������������������������������Ŀ
//� Declaracao de variaveis                                      �
//����������������������������������������������������������������
Local oModel		:= FWLoadModel('TCRMA006')
Local oStruZX5	:= FWFormStruct(2,'ZX5',{|cCampo| AllTrim(cCampo) $ "ZX5_TABELA|ZX5_DESCRI|ZX5_DESENG|ZX5_DESESP"})
Local oStruZX52	:= FWFormStruct(2,'ZX5')
Local oView		:= Nil

//��������������������������������������������������������������Ŀ
//� Remove campos da oStruZX5/oStruZX52			                 �
//����������������������������������������������������������������
oStruZX5:RemoveField('ZX5_CHAVE')
oStruZX5:RemoveField('ZX5_CHAVE2') 

oStruZX52:RemoveField('ZX5_TABELA')

//��������������������������������������������������������������Ŀ
//� Cria o objeto de View	                                     �
//����������������������������������������������������������������
oView := FWFormView():New()
oView:SetModel(oModel)
oView:AddField('FORM1', oStruZX5, 'DADOSZX5')
oView:AddGrid('FORM2', oStruZX52, 'DADOSZX52')
oView:CreateHorizontalBox('SUPERIOR', 50)
oView:CreateHorizontalBox('INFERIOR', 50)
oView:SetOwnerView('FORM1', 'SUPERIOR')
oView:SetOwnerView('FORM2', 'INFERIOR')

//��������������������������������������������������������������Ŀ
//� Titulo das Pastas                      						 �
//����������������������������������������������������������������
oView:EnableTitleView('FORM1' , STR0011)	// 'CABEC.CONSULTA' 
oView:EnableTitleView('FORM2' , STR0012)	// 'ITENS CONSULTA'

Return(oView)

/*/{Protheus.doc} GeraWizard

Parametrizar a Consulta Padr�o

@author Anderson Alberto
@since 19/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

User Function GeraWizard()

//��������������������������������������������������������������Ŀ
//� Declaracao de variaveis                                      �
//����������������������������������������������������������������
Local oWizard	:= Nil

//��������������������������������������������������������������Ŀ
//� Monta Wizard para selecao dos dados                          �
//����������������������������������������������������������������
DEFINE WIZARD oWizard ;
	TITLE STR0013;			// 'Assistente para Parametrizar a Consulta Padr�o'
	HEADER STR0014;			// 'Aten��o'
	MESSAGE STR0015;		// 'Siga os pr�ximos passos para definir os par�metros para sele��o dos Parametrizar a Consulta Padr�o.'
	TEXT +CRLF+STR0016;		// 'Esta rotina tem como objetivo ajuda-lo na defini��o dos filtros a serem aplicados na Consulta Padr�o. '
	NEXT {|| .T.} ;
	FINISH {||.T.}

//��������������������������������������������������������������Ŀ
//� Painel de selecao dos filtros iniciais                       �
//����������������������������������������������������������������
CREATE PANEL oWizard  ;
	HEADER STR0013 ;		// 'Assistente para sele��o dos dados para Consulta Padr�o'
	MESSAGE STR0017;		// 	'Parametros Iniciais'
	BACK {|| .T.} ;
	NEXT {|| VldSelArr(aTpContr, STR0018)} ;	// 'Selecione ao menos 1 tipo de contrato.'
	PANEL

ACTIVATE WIZARD oWizard CENTERED

Return()

/*/{Protheus.doc} TC06Get
TODO Observa��o auto-gerada.

@author Anderson Alberto
@since 19/05/2015
@version 
@param cTabela, char, c�digo da tabela
@param cChave, char, c�digo da chave
@param cChave2, char, c�digo da chave 2
@param nCampo, num, tipo de retorno (1=ZX5_DESC, 2=ZX5_COMPL)
@type function
@return cRet, Valor da tabela
/*/

User Function TC06Get(cTabela,cChave,cChave2,nCampo)

//��������������������������������������������������������������Ŀ
//� Declaracao de variaveis                                      �
//����������������������������������������������������������������
Local aArea		:= GetArea()
Local cRet		:= ''

Default cChave	:= Space(tamSX3("ZX5_CHAVE")[1])
Default cChave2:= Space(tamSX3("ZX5_CHAVE2")[1])
Default nCampo	:= 1

//��������������������������������������������������������������Ŀ
//� Pesquisa dados conforme parametros                           �
//����������������������������������������������������������������
ZX5->(DbSetOrder(1))
ZX5->(DbSeek(xFilial('ZX5')+cTabela+cChave+cChave2))
cRet := Alltrim(Iif(nCampo == 1, ZX5->ZX5_DESC, ZX5->ZX5_COMPL))

RestArea(aArea)

Return(cRet)


/*/{Protheus.doc} nomeFunction
	(long_description)
	@type  Function
	@author eder.oliveira
	@since 25/04/2017
	@version 1.0
	@param nTipo, numeric, opera��o
	@param oModel, object, modelo
	@param nNumero, numeric, linha
	@param cTabela, char, tabela
	@return aRet, array, itens da tabela
	/*/
Static Function TA06Load(nTipo,oModel,nNumero,cTabela)
Local aArea			:= GetArea()
Local aAreaZX5		:= ZX5->(GetArea())
Local aRet			:= {}
Local cTemp			:= GetNextAlias()
Local oStruIte		:= oModel:GetStruct()
Local nI			:= 0
Local nPos			:= 0

dbSelectArea("ZX5")
dbSetOrder(1)
dbSeek(xFilial("ZX5")+cTabela)

Do WHile !ZX5->(EoF()) .and. ZX5->(ZX5_FILIAL+ZX5_TABELA)==xFilial("ZX5")+cTabela

	If Empty(ZX5->ZX5_CHAVE) .and. Empty(ZX5->ZX5_CHAVE2)
		ZX5->(dbSkip())
		Loop
	EndIf
	
	aAdd(aRet,{ ZX5->(Recno()) , {}})
	nPos := Len(aRet)
	
	For nI := 1 to Len(oStruIte:aFields)
		aAdd(aRet[nPos,2],ZX5->(FieldGet(FieldPos(oStruIte:aFields[nI,3]))))
	Next nI
	
	ZX5->(dbSkip())
	
EndDo

RestArea(aAreaZX5)
RestArea(aArea)
Return(aRet)