% =============================================================================
% MUNDO DOS BLOCOS — Planejamento com move(B, Pi, Pj)
% Compatível com SWISH (swish.swi-prolog.org)
%
% LARGURAS DOS BLOCOS:
%   a → largura 1   b → largura 1   c → largura 2   d → largura 3
%
% REPRESENTAÇÃO DO ESTADO:
%   Lista de pos(Bloco, ColunaEsquerda, Altura)
%     • ColunaEsquerda : coluna mais à esquerda do bloco
%     • Altura         : 0 = chão; N = N blocos abaixo (em todas as suas colunas)
%
% AÇÃO:  move(B, Pi, Pj)
%   Pré-condições:
%     1. B está com coluna-esquerda Pi.
%     2. B está livre (nenhum bloco acima em QUALQUER coluna que ocupa).
%     3. Pi ≠ Pj.
%     4. Pj + largura(B) - 1 ≤ 6  (cabe no grid).
%     5. A altura de destino é válida (blocos abaixo formam superfície plana).
%     6. Não há sobreposição com outros blocos no destino.
% =============================================================================


% =============================================================================
%  LARGURAS
% =============================================================================
largura(a, 1).
largura(b, 1).
largura(c, 2).
largura(d, 3).

% colunas_do_bloco(+Bloco, +ColEsq, -ListaColunas)
colunas_do_bloco(Bloco, ColEsq, Cols) :-
    largura(Bloco, L),
    ColDir is ColEsq + L - 1,
    ColDir =< 6,
    numlist(ColEsq, ColDir, Cols).


% =============================================================================
%  PRIMITIVAS DE ESTADO
% =============================================================================

%% topo_livre(+Estado, +Bloco)
%  Verdadeiro se NENHUMA coluna que Bloco ocupa tiver algo acima dele.
topo_livre(Estado, Bloco) :-
    member(pos(Bloco, Col, Alt), Estado),
    colunas_do_bloco(Bloco, Col, Cols),
    \+ (
        member(pos(Outro, ColO, AltO), Estado),
        Outro \= Bloco,
        colunas_do_bloco(Outro, ColO, ColsO),
        AltO > Alt,                          % Outro está acima
        intersecao(Cols, ColsO, [_|_])       % e compartilha coluna com Bloco
    ).

%% intersecao(+L1, +L2, -Inter)
intersecao(L1, L2, Inter) :-
    include(member_(L2), L1, Inter).
member_(L, X) :- member(X, L).

%% altura_destino(+Estado, +Bloco, +ColEsq, -H)
%  H = altura que Bloco ficará ao pousar em ColEsq.
%  É o máximo de (Alt + Largura_bloco_embaixo) em todas as colunas que vai ocupar,
%  considerando somente blocos cujo topo coincide com a superfície naquelas colunas.
%
%  Regra simplificada usada aqui:
%    H = máxima "altura de superfície" dentre todas as colunas de destino.
%    Altura de superfície de uma coluna C = max(Alt+1) para blocos que incluem C,
%    ou 0 se vazia.
altura_destino(Estado, Bloco, ColEsq, H) :-
    colunas_do_bloco(Bloco, ColEsq, Cols),
    maplist(superficie_coluna(Estado), Cols, Alts),
    max_list(Alts, H).

%% superficie_coluna(+Estado, +Col, -H)
%  Altura do topo da pilha na coluna Col (0 se vazia).
superficie_coluna(Estado, Col, H) :-
    findall(AltTopo,
        (   member(pos(B, ColB, AltB), Estado),
            colunas_do_bloco(B, ColB, Cols),
            member(Col, Cols),
            AltTopo is AltB + 1
        ),
        Alts),
    (Alts = [] -> H = 0 ; max_list(Alts, H)).

%% sem_sobreposicao(+Estado)
%  Verifica que nenhum par de blocos distintos ocupa a mesma (coluna, altura).
sem_sobreposicao(Estado) :-
    \+ (
        member(pos(B1, C1, A1), Estado),
        member(pos(B2, C2, A2), Estado),
        B1 @< B2,
        colunas_do_bloco(B1, C1, Cols1),
        colunas_do_bloco(B2, C2, Cols2),
        intersecao(Cols1, Cols2, [_|_]),     % mesmas colunas
        A1 =:= A2                            % mesma altura → sobreposição!
    ).

%% aplicar_move(+Estado, +B, +Pi, +Pj, -NovoEstado)
aplicar_move(Estado, B, Pi, Pj, NovoEstado) :-
    Pi \= Pj,
    member(pos(B, Pi, _), Estado),           % B está em Pi
    topo_livre(Estado, B),                   % B está livre
    colunas_do_bloco(B, Pj, _),             % Pj válido no grid (falha se sair)
    select(pos(B, Pi, _), Estado, Temp),     % remove B temporariamente
    altura_destino(Temp, B, Pj, H),          % altura de pouso em Pj
    NovoEstado = [pos(B, Pj, H) | Temp],
    sem_sobreposicao(NovoEstado).            % segurança extra


% =============================================================================
%  BUSCA EM LARGURA — BFS
% =============================================================================

resolve(S0, Sf, Plano) :-
    bfs([[S0, []]], Sf, PlanRev),
    reverse(PlanRev, Plano).

bfs([[Estado, Plano] | _], Objetivo, Plano) :-
    mesmo_estado(Estado, Objetivo), !.

bfs([[Estado, Plano] | Resto], Objetivo, PlanFinal) :-
    findall(
        [Novo, [move(B,Pi,Pj) | Plano]],
        (   member(pos(B, Pi, _), Estado),
            member(Pj, [0,1,2,3,4,5,6]),
            aplicar_move(Estado, B, Pi, Pj, Novo),
            \+ ja_visitado(Novo, Resto)
        ),
        Filhos
    ),
    append(Resto, Filhos, NovaFila),
    bfs(NovaFila, Objetivo, PlanFinal).

mesmo_estado(E1, E2) :- msort(E1, S), msort(E2, S).

ja_visitado(Estado, Fila) :-
    member([E, _], Fila), mesmo_estado(E, Estado), !.


% =============================================================================
%  UTILITÁRIO DE EXIBIÇÃO
% =============================================================================

exibir_plano([], N) :-
    format("  (~w movimentos no total)~n", [N]).
exibir_plano([move(B,Pi,Pj) | Resto], N) :-
    format("  ~w. move(~w, ~w, ~w)~n", [N, B, Pi, Pj]),
    N1 is N + 1,
    exibir_plano(Resto, N1).

resolver_e_exibir(Label, S0, Sf) :-
    format("~n--- ~w ---~n", [Label]),
    (   resolve(S0, Sf, Plano)
    ->  exibir_plano(Plano, 1)
    ;   write("  [sem solucao]"), nl
    ).


% =============================================================================
%  SITUAÇÃO 1
% =============================================================================
%
%  Grid (posições da coluna-esquerda de cada bloco):
%
%  S0:   c@col0(h0), a@col2(h0), b@col3(h0), d@col4(h0)
%
%    Col: 0  1  2  3  4  5  6
%         [c  c] a  b [d  d  d]
%
%  Sf1:  c@col0(h0), a@col2(h0), b@col3(h0), d@col4(h0)  → reordenação no chão
%    Col: 0  1  2  3  4  5  6
%         a  b [c  c][d  d  d]
%
%  Sf2:  a@col0(h0), c@col1(h0), d@col3(h0), b@col6(h0)
%    Col: 0  1  2  3  4  5  6
%         a [c  c][d  d  d]  b
%
%  Sf3:  d@col0(h0), c@col3(h0), a@col5(h0), b@col6(h0)
%    Col: 0  1  2  3  4  5  6
%        [d  d  d][c  c] a  b
%
%  Sf4:  d@col0(h0), a@col3(h0), b@col4(h0), c@col5(h0)
%    Col: 0  1  2  3  4  5  6
%        [d  d  d] a  b [c  c]
% =============================================================================

situacao1 :-
    write("============================================"), nl,
    write("              SITUACAO 1                    "), nl,
    write("============================================"), nl,

    S0  = [pos(c,0,0), pos(a,2,0), pos(b,3,0), pos(d,4,0)],

    Sf1 = [pos(a,0,0), pos(b,1,0), pos(c,2,0), pos(d,4,0)],
    resolver_e_exibir('S0 -> Sf1  [a col0, b col1, c col2, d col4]', S0, Sf1),

    Sf2 = [pos(a,0,0), pos(c,1,0), pos(d,3,0), pos(b,6,0)],
    resolver_e_exibir('S0 -> Sf2  [a col0, c col1, d col3, b col6]', S0, Sf2),

    Sf3 = [pos(d,0,0), pos(c,3,0), pos(a,5,0), pos(b,6,0)],
    resolver_e_exibir('S0 -> Sf3  [d col0, c col3, a col5, b col6]', S0, Sf3),

    Sf4 = [pos(d,0,0), pos(a,3,0), pos(b,4,0), pos(c,5,0)],
    resolver_e_exibir('S0 -> Sf4  [d col0, a col3, b col4, c col5]', S0, Sf4).


% =============================================================================
%  SITUAÇÃO 2
% =============================================================================
%
%  S0:  a@col0(h0), c@col1(h0), b@col3(h0), d@col4(h0)
%    Col: 0  1  2  3  4  5  6
%         a [c  c] b [d  d  d]
%
%  S1:  b move col3 → col6
%    Col: 0  1  2  3  4  5  6
%         a [c  c]   [d  d  d] b
%
%  S2:  c move col1 → col3
%    Col: 0  1  2  3  4  5  6
%         a        [c  c][d  d  d] b
%
%  S3:  a move col0 → col1
%    Col: 0  1  2  3  4  5  6
%              a  [c  c][d  d  d] b
%
%  S4:  b move col6 → col0
%    Col: 0  1  2  3  4  5  6
%         b  a  [c  c][d  d  d]
%
%  S5 (meta):  b move col0 → col1... ajustado para encaixe final
%    Col: 0  1  2  3  4  5  6
%         a  b [c  c][d  d  d]
% =============================================================================

situacao2 :-
    write("============================================"), nl,
    write("              SITUACAO 2                    "), nl,
    write("============================================"), nl,

    S0 = [pos(a,0,0), pos(c,1,0), pos(b,3,0), pos(d,4,0)],
    S1 = [pos(a,0,0), pos(c,1,0), pos(b,6,0), pos(d,4,0)],
    S2 = [pos(a,0,0), pos(c,3,0), pos(b,6,0), pos(d,4,0)],
    S3 = [pos(a,1,0), pos(c,3,0), pos(b,6,0), pos(d,4,0)],
    S4 = [pos(b,0,0), pos(a,1,0), pos(c,3,0), pos(d,4,0)],
    S5 = [pos(a,0,0), pos(b,1,0), pos(c,2,0), pos(d,4,0)],

    resolver_e_exibir('S0 -> S1', S0, S1),
    resolver_e_exibir('S1 -> S2', S1, S2),
    resolver_e_exibir('S2 -> S3', S2, S3),
    resolver_e_exibir('S3 -> S4', S3, S4),
    resolver_e_exibir('S4 -> S5', S4, S5),
    nl, write("  ==== Plano COMPLETO ===="), nl,
    resolver_e_exibir('S0 -> S5', S0, S5).


% =============================================================================
%  SITUAÇÃO 3
% =============================================================================
%
%  S0:  c@col0(h0), a@col2(h0), b@col3(h0), d@col4(h0)
%    Col: 0  1  2  3  4  5  6
%        [c  c] a  b [d  d  d]
%
%  S1:  a move col2 → col6
%    Col: 0  1  2  3  4  5  6
%        [c  c]    b [d  d  d] a
%
%  S2:  b move col3 → col2
%    Col: 0  1  2  3  4  5  6
%        [c  c] b    [d  d  d] a
%
%  S3:  d move col4 → col3
%    Col: 0  1  2  3  4  5  6
%        [c  c] b  [d  d  d]   a
%
%  S4:  a move col6 → col5
%    Col: 0  1  2  3  4  5  6
%        [c  c] b  [d  d  d] a
%
%  S5:  a sobe sobre c → a@col1(h1)
%    Col: 0  1  2  3  4  5  6
%        [c  c] b  [d  d  d]
%         .  a
%
%  S6:  d move col3 → col4
%    Col: 0  1  2  3  4  5  6
%        [c  c] b     [d  d  d]
%         .  a
%
%  S7 (meta):  b move col2 → col3
%    Col: 0  1  2  3  4  5  6
%        [c  c]    b  [d  d  d]
%         .  a
% =============================================================================

situacao3 :-
    write("============================================"), nl,
    write("              SITUACAO 3                    "), nl,
    write("============================================"), nl,

    S0 = [pos(c,0,0), pos(a,2,0), pos(b,3,0), pos(d,4,0)],
    S1 = [pos(c,0,0), pos(a,6,0), pos(b,3,0), pos(d,4,0)],
    S2 = [pos(c,0,0), pos(a,6,0), pos(b,2,0), pos(d,4,0)],
    S3 = [pos(c,0,0), pos(a,6,0), pos(b,2,0), pos(d,3,0)],
    S4 = [pos(c,0,0), pos(a,5,0), pos(b,2,0), pos(d,3,0)],
    S5 = [pos(c,0,0), pos(a,1,1), pos(b,2,0), pos(d,3,0)],
    S6 = [pos(c,0,0), pos(a,1,1), pos(b,2,0), pos(d,4,0)],
    S7 = [pos(c,0,0), pos(a,1,1), pos(b,3,0), pos(d,4,0)],

    resolver_e_exibir('S0 -> S1', S0, S1),
    resolver_e_exibir('S1 -> S2', S1, S2),
    resolver_e_exibir('S2 -> S3', S2, S3),
    resolver_e_exibir('S3 -> S4', S3, S4),
    resolver_e_exibir('S4 -> S5', S4, S5),
    resolver_e_exibir('S5 -> S6', S5, S6),
    resolver_e_exibir('S6 -> S7', S6, S7),
    nl, write("  ==== Plano COMPLETO ===="), nl,
    resolver_e_exibir('S0 -> S7', S0, S7).
