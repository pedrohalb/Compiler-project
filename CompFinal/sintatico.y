%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lexico.c"
#include "utils.c"
int contaVar = 0;
int rotulo = 0;
int ehRegistro = 0;
int posTipo = 0;
int tipo;
int pos;
int tam;
int des;
int indice;
int end;
listaCampos* listaC;
listaCampos *listaBuscada;
listadelistaC *listadeListaC;
%}

%token T_PROGRAMA
%token T_INICIO
%token T_FIM
%token T_IDENTIF
%token T_LEIA
%token T_ESCREVA
%token T_ENQTO
%token T_FACA
%token T_FIMENQTO
%token T_SE
%token T_ENTAO
%token T_SENAO
%token T_FIMSE
%token T_ATRIB
%token T_VEZES
%token T_DIV
%token T_MAIS
%token T_MENOS
%token T_MAIOR
%token T_MENOR
%token T_IGUAL
%token T_E
%token T_OU
%token T_V
%token T_F
%token T_NUMERO
%token T_NAO
%token T_ABRE
%token T_FECHA
%token T_LOGICO
%token T_INTEIRO
%token T_DEF
%token T_FIMDEF
%token T_REGISTRO
%token T_IDPONTO

%start programa

%left T_E T_OU
%left T_IGUAL
%left T_MAIOR T_MENOR
%left T_MAIS T_MENOS
%left T_VEZES T_DIV

%%

programa 
   : cabecalho definicoes variaveis 
        { 
            mostraTabela();
            empilha (contaVar);
            if (contaVar)
               fprintf(yyout, "\tAMEM\t%d\n", contaVar); 
        }
     T_INICIO lista_comandos T_FIM
        { 
            int conta = desempilha();
            if (conta)
               fprintf(yyout, "\tDMEM\t%d\n", conta); 
        }
        { fprintf(yyout, "\tFIMP\n"); }
   ;

cabecalho
   : T_PROGRAMA T_IDENTIF
       { 
         fprintf(yyout, "\tINPP\n"); 
         
         elemTab.tip = INT;
         elemTab.end = -1;
         strcpy(elemTab.id, "inteiro");
         elemTab.listaDeCampos = NULL;
         elemTab.posicao = posTipo++;
         elemTab.tam = 1;
         insereSimbolo(elemTab);
         
         elemTab.tip = LOG;
         elemTab.end = -1;
         strcpy(elemTab.id, "logico");
         elemTab.listaDeCampos = NULL;
         elemTab.posicao = posTipo++;;
         elemTab.tam = 1;
         insereSimbolo(elemTab);

         listadeListaC = inicializaListadelistaC();
       }
   ;

// TODO #1 -- define tam e pos para os tipos
tipo
   : T_LOGICO
         { 
            tipo = LOG; 
            tam = 1;
            pos = 1;
         }
   | T_INTEIRO
         { 
            tipo = INT;
            tam = 1;
            pos = 0;
        }
   | T_REGISTRO T_IDENTIF
         { 
            // TODO #2 --- em caso de tipo registro, buscar tam e pos na tabela de simobolo a partir do atomo (não é predefinido)
            tipo = REG; 
            indice = buscaSimbolo(atomo);
            tam = tabSimb[indice].tam;
            pos = tabSimb[indice].posicao;
         }
   ;

definicoes
   : define definicoes
   | /* vazio */
   ;

define 
   : T_DEF
        {
        // TODO #3 --- inicializar uma nova lista de campos para o registro a ser criado
         listaC = inicializaListaCampos();
        } 
   definicao_campos T_FIMDEF T_IDENTIF
       {
          // TODO #4 - inserir registro criado na tabela, junto com seus respectivos campos
           elemTab.tip = REG;
           elemTab.end = -1;
           strcpy(elemTab.id, atomo);
           elemTab.listaDeCampos = listaC;
           elemTab.posicao = posTipo++;
           elemTab.tam = tamanhoListaCampos(listaC);
           insereSimbolo(elemTab);
       }
   ;

definicao_campos
   : tipo lista_campos definicao_campos
   | tipo lista_campos
   ;

// TODO #5 - acrescentar campo na lista de campos do registro, que está sendo construída
lista_campos
   : lista_campos T_IDENTIF
      {
         if (listaC) des = listaC->deslocamento + listaC->tamanho; 
         else des = 0;
         
         listaC = adicionaCampo(listaC, atomo, tipo, pos, des, tam);
         listadeListaC = adicionaListadeLista(listadeListaC, listaC);
      }
   | T_IDENTIF
      {
         if (listaC) des = listaC->deslocamento + listaC->tamanho;
         else des = 0;

        listaC = adicionaCampo(listaC, atomo, tipo, pos, des, tam);
        listadeListaC = adicionaListadeLista(listadeListaC, listaC);
      }
   ;

variaveis
   : /* vazio */
   | declaracao_variaveis
   ;

declaracao_variaveis
   : tipo lista_variaveis declaracao_variaveis
   | tipo lista_variaveis
   ;

// TODO 6 - acrescentar variável declarada na tabela de símbolos
     // TODO 7 - em caso de registro o contaVar recebe contaVar + tamanho do registro
lista_variaveis
   : lista_variaveis
     T_IDENTIF 
        { 
            strcpy(elemTab.id, atomo);
            elemTab.end = contaVar;
            elemTab.tip = tipo;
            elemTab.posicao = pos;
            elemTab.tam = tam;
            elemTab.listaDeCampos = tabSimb[pos].listaDeCampos;
            insereSimbolo (elemTab);
            contaVar += tam; 
        }
   | T_IDENTIF
       { 
            strcpy(elemTab.id, atomo);
            elemTab.end = contaVar;
            elemTab.tip = tipo;
            elemTab.posicao = pos;
            elemTab.tam = tam;
            elemTab.listaDeCampos = tabSimb[pos].listaDeCampos;
            insereSimbolo (elemTab);
            contaVar += tam;
       }
   ;

lista_comandos
   : /* vazio */
   | comando lista_comandos
   ;

comando
   : entrada_saida
   | atribuicao
   | selecao
   | repeticao
   ;

entrada_saida
   : entrada
   | saida 
   ;


// TODO 8 - fazer repetição de leituras, em casos de tipo registro
entrada
   : T_LEIA expressao_acesso
       { 
         indice = buscaSimbolo(atomo);
         
         if (indice == -1) {
            listaBuscada = buscaCampoListadeLista(listadeListaC, atomo);
            
            if (listaBuscada) {
               indice = listaBuscada->posicao;
            } else {
               char msg[200];
               sprintf(msg, "Identificador [%s] não encontrado!", atomo);
               yyerror (msg);
            }
         }

         if (tipo == REG) {
            for(int i = 0; i < tam; i++) {
               fprintf(yyout, "\tLEIA\n"); 
               fprintf(yyout, "\tARZG\t%d\n", tabSimb[indice].end + i);  
            } 
          } else {
             fprintf(yyout, "\tLEIA\n"); 
             fprintf(yyout, "\tARZG\t%d\n", des);
          }
      }
   ;

// TODO 9 - em caso de registro, repetir leitura de acordo com o tamanho
saida
   : T_ESCREVA expressao
      {  
         desempilha(); 
         if (tipo == REG) {
            for (int i = 0; i < tam; i++) {
               fprintf(yyout, "\tESCR\n");
            }
          } else {
              fprintf(yyout, "\tESCR\n");
          }
      }
   ;

// TODO 10 - feito
atribuicao
   : expressao_acesso
       { 
          empilha(tam);
          empilha(des);
          empilha(tipo);
       }
     T_ATRIB expressao
       { 
          int tipexp = desempilha();
          int tipvar = desempilha();
          int des = desempilha();
          int tam = desempilha();
          if (tipexp != tipvar)
             yyerror("Incompatibilidade de tipo!");
           // TODO 11 - feito
           for (int i = 0; i < tam; i++) 
             fprintf(yyout, "\tARZG\t%d\n", des + i); 
       }
   ;

selecao
   : T_SE expressao T_ENTAO 
       {  
          int t = desempilha();
          if (t != LOG)
            yyerror("Incompatibilidade de tipo!");
          fprintf(yyout, "\tDSVF\tL%d\n", ++rotulo); 
          empilha(rotulo);
       }
     lista_comandos T_SENAO 
       {  
           fprintf(yyout, "\tDSVS\tL%d\n", ++rotulo);
           int rot = desempilha(); 
           fprintf(yyout, "L%d\tNADA\n", rot);
           empilha(rotulo); 
       }
     lista_comandos T_FIMSE
       {  
          int rot = desempilha();
          fprintf(yyout, "L%d\tNADA\n", rot);  
       }
   ;

repeticao
   : T_ENQTO 
       { 
         fprintf(yyout, "L%d\tNADA\n", ++rotulo);
         empilha(rotulo);  
       }
     expressao T_FACA 
       {  
         int t = desempilha();
         if (t != LOG)
            yyerror("Incompatibilidade de tipo!");
         fprintf(yyout, "\tDSVF\tL%d\n", ++rotulo); 
         empilha(rotulo);
       }
     lista_comandos T_FIMENQTO
       { 
          int rot1 = desempilha();
          int rot2 = desempilha();
          fprintf(yyout, "\tDSVS\tL%d\n", rot2);
          fprintf(yyout, "L%d\tNADA\n", rot1);  
       }
   ;

expressao
   : expressao T_VEZES expressao
       {  testaTipo(INT,INT,INT); fprintf(yyout, "\tMULT\n");  }
   | expressao T_DIV expressao
       {  testaTipo(INT,INT,INT); fprintf(yyout, "\tDIVI\n");  }
   | expressao T_MAIS expressao
      {  testaTipo(INT,INT,INT); fprintf(yyout, "\tSOMA\n");  }
   | expressao T_MENOS expressao
      {  testaTipo(INT,INT,INT); fprintf(yyout, "\tSUBT\n");  }
   | expressao T_MAIOR expressao
      {  testaTipo(INT,INT,LOG); fprintf(yyout, "\tCMMA\n");  }
   | expressao T_MENOR expressao
      {  testaTipo(INT,INT,LOG); fprintf(yyout, "\tCMME\n");  }
   | expressao T_IGUAL expressao
      {  testaTipo(INT,INT,LOG); fprintf(yyout, "\tCMIG\n");  }
   | expressao T_E expressao
      {  testaTipo(LOG,LOG,LOG); fprintf(yyout, "\tCONJ\n");  }
   | expressao T_OU expressao
      {  testaTipo(LOG,LOG,LOG); fprintf(yyout, "\tDISJ\n");  }
   | termo
   ;

expressao_acesso
   : T_IDPONTO
       {   //--- Primeiro nome do registro
           if (!ehRegistro) {
              // TODO 11 - guardar tam pos e des do identificador
              ehRegistro = 1;
              indice = buscaSimbolo(atomo);
              if (tipo != REG) {
                  char msg[200];
                  sprintf(msg, "Erro: O identificador [%s] não é registro!", atomo);
                  yyerror (msg);
              } 
               tam = tabSimb[indice].tam;
               pos = tabSimb[indice].posicao;
               des = tabSimb[indice].end;

               //end do primeiro nome do registro é guardado
               end = tabSimb[indice].end;
           } else {
               // guarda informações do campo que eh registro 
               listaBuscada = buscaCampoListadeLista(listadeListaC, atomo);
               
               if (!listaBuscada) {
                   char msg[200];
                   sprintf(msg, "O campo [%s] não existe na estrutura", atomo);
                   yyerror (msg);
               } else if (listaBuscada->tip != REG) {
                   char msg[200];
                   sprintf(msg, "O campo [%s] não é registro!", atomo);
                   yyerror (msg);
               }
               tam = listaBuscada->tamanho;
               pos = listaBuscada->posicao;
               des = listaBuscada->deslocamento;
           }
       }
     expressao_acesso
   | T_IDENTIF
       {   
           if (ehRegistro) {
              listaBuscada = buscaCampoListadeLista(listadeListaC, atomo);
              if (!listaBuscada) {
                  char msg[200];
                  sprintf(msg, "O campo [%s] não existe na estrutura", atomo);
                  yyerror (msg);
               }
               tam = listaBuscada->tamanho;
               tipo = listaBuscada->tip;
               des = tabSimb[indice].end + listaBuscada->deslocamento;
           }
           else {
              indice = buscaSimbolo (atomo);
              tam = tabSimb[indice].tam;
              des = tabSimb[indice].end;
              tipo = tabSimb[indice].tip;
           }
           ehRegistro = 0;
       };

termo
   : expressao_acesso
       {
         // TODO 15 - fazer repetição do CRVG em caso de tipo registro
         indice = buscaSimbolo(atomo);
         
         if (indice == -1) {
            listaBuscada = buscaCampoListadeLista(listadeListaC, atomo);
            
            if (listaBuscada) {
               indice = listaBuscada->posicao;
            } else {
               char msg[200];
               sprintf(msg, "Identificador [%s] não encontrado!", atomo);
               yyerror (msg);
            }
         }

         if (tipo == REG) {
            for(int i = tam - 1; i >= 0; i--) 
               fprintf(yyout, "\tCRVG\t%d\n", tabSimb[end].posicao + tabSimb[indice].end + i);  
         } else 
               fprintf(yyout, "\tCRVG\t%d\n", des);

         empilha(tipo);
       }
   | T_NUMERO
       {  
          fprintf(yyout, "\tCRCT\t%s\n", atomo);  
          empilha(INT);
       }
   | T_V
       {  
          fprintf(yyout, "\tCRCT\t1\n");
          empilha(LOG);
       }
   | T_F
       {  
          fprintf(yyout, "\tCRCT\t0\n"); 
          empilha(LOG);
       }
   | T_NAO termo
       {  
          int t = desempilha();
          if (t != LOG)
              yyerror ("Incompatibilidade de tipo!");
          fprintf(yyout, "\tNEGA\n");
          empilha(LOG);
       }
   | T_ABRE expressao T_FECHA
   ;
%%

int main(int argc, char *argv[]) {
    char *p, nameIn[100], nameOut[100];
    argv++;
    if (argc < 2) {
        puts("\nCompilador da linguagem SIMPLES");
        puts("\n\tUSO: ./simples <NOME>[.simples]\n\n");
        exit(1);
    }
    p = strstr(argv[0], ".simples");
    if (p) *p = 0;
    strcpy(nameIn, argv[0]);
    strcat(nameIn, ".simples");
    strcpy(nameOut, argv[0]);
    strcat(nameOut, ".mvs");
    yyin = fopen(nameIn, "rt");
    if (!yyin) {
        puts ("Programa fonte não encontrado!");
        exit(2);
    }
    yyout = fopen(nameOut, "wt");
    yyparse();
    printf("programa ok!\n\n");
    return 0;
}