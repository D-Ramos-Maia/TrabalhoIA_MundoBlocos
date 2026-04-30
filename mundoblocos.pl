% =============================================================================
% MUNDO DOS BLOCOS — Planejamento com move(B, Pi, Pj)
% Compatível com SWISH (swish.swi-prolog.org)
%
% Para executar cada situação, chame no painel de query:
%   ?- situacao1.
%   ?- situacao2.
%   ?- situacao3.
%
% REPRESENTAÇÃO DO ESTADO:
%   Lista de pos(Bloco, Coluna, Altura)
%     • Bloco  : a, b, c ou d
%     • Coluna : inteiro 0..6
%     • Altura : 0 = chão; N = N blocos abaixo
%
% AÇÃO:  move(B, Pi, Pj)
%   Pré-condições:
%     1. B está na coluna Pi.
%     2. B está livre (nenhum bloco acima dele).
%     3. Pi ≠ Pj.
% =============================================================================


% =============================================================================
%  PRIMITIVAS DE ESTADO
% =============================================================================

%% topo_livre(+Estado, +Bloco)
%  Verdadeiro se nenhum bloco estiver acima de Bloco na mesma coluna.
topo_livre(Estado, Bloco) :-
    member(pos(Bloco, Col, Alt), Estado),
    \+ (member(pos(_, Col, AltX), Estado), AltX > Alt).

%% altura_coluna(+Estado, +Col, -H)
%  H = número de blocos atualmente na coluna Col.
%  Usamos findall em vez de aggregate_all (compatível com SWISH).
altura_coluna(Estado, Col, H) :-
    findall(_, member(pos(_, Col, _), Estado), Lista),
    length(Lista, H).

%% aplicar_move(+Estado, +B, +Pi, +Pj, -NovoEstado)
%  Gera NovoEstado após mover B de Pi para Pj, ou falha se inválido.
aplicar_move(Estado, B, Pi, Pj, NovoEstado) :-
    Pi \= Pj,
    member(pos(B, Pi, _), Estado),
    topo_livre(Estado, B),
    altura_coluna(Estado, Pj, NovaAlt),
    select(pos(B, Pi, _), Estado, Temp),
    NovoEstado = [pos(B, Pj, NovaAlt) | Temp].


% =============================================================================
%  BUSCA EM LARGURA — BFS
%  Garante o plano com menor número de movimentos.
% =============================================================================

%% resolve(+S0, +Sf, -Plano)
%  Plano = lista ordenada de move/3 que leva de S0 a Sf.
resolve(S0, Sf, Plano) :-
    bfs([[S0, []]], Sf, PlanRev),
    reverse(PlanRev, Plano).

% Nó da fila: [Estado, PlanoAcumuladoReverso]
bfs([[Estado, Plano] | _], Objetivo, Plano) :-
    mesmo_estado(Estado, Objetivo), !.

bfs([[Estado, Plano] | Resto], Objetivo, PlanFinal) :-
    findall(
        [Novo, [move(B,Pi,Pj) | Plano]],
        (   member(pos(B, Pi, _), Estado),
            member(Pj, [0,1,2,3,4,5,6]),
            aplicar_move(Estado, B, Pi, Pj, Novo),
            \+ ja_na_fila(Novo, Resto)
        ),
        Filhos
    ),
    append(Resto, Filhos, NovaFila),
    bfs(NovaFila, Objetivo, PlanFinal).

%% mesmo_estado(+E1, +E2)
mesmo_estado(E1, E2) :- msort(E1, S), msort(E2, S).

%% ja_na_fila(+Estado, +Fila)
ja_na_fila(Estado, Fila) :-
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
%  S0:
%    Col: 0  1  2  3  4  5  6
%              c     d     b
%                    a
%    pos: c@col1(h0), a@col3(h0), d@col3(h1)[sobre a], b@col5(h0)
%
%  ─────────────────────────────────────────────────────
%  Sf1: torre d-a-c na col4, b livre na col5
%    Col: 0  1  2  3  4  5  6
%                       c  b
%                       a
%                       d
%  ─────────────────────────────────────────────────────
%  Sf2: torre d-c na col4, torre a-b na col5
%    Col: 0  1  2  3  4  5  6
%                       c  b
%                       d  a
%  ─────────────────────────────────────────────────────
%  Sf3: torre c-d na col1, a@col2, b@col5
%    Col: 0  1  2  3  4  5  6
%              d  a        b
%              c
%  ─────────────────────────────────────────────────────
%  Sf4: todos no chão — a@col0, c@col1, d@col2, b@col5
%    Col: 0  1  2  3  4  5  6
%         a  c  d        b
% =============================================================================

situacao1 :-
    write("============================================"), nl,
    write("              SITUACAO 1                    "), nl,
    write("============================================"), nl,

    S0  = [pos(c,1,0), pos(a,3,0), pos(d,3,1), pos(b,5,0)],

    Sf1 = [pos(d,4,0), pos(a,4,1), pos(c,4,2), pos(b,5,0)],
    resolver_e_exibir('S0 -> Sf1  [torre d-a-c col4, b col5]', S0, Sf1),

    Sf2 = [pos(d,4,0), pos(c,4,1), pos(a,5,0), pos(b,5,1)],
    resolver_e_exibir('S0 -> Sf2  [torre d-c col4, torre a-b col5]', S0, Sf2),

    Sf3 = [pos(c,1,0), pos(d,1,1), pos(a,2,0), pos(b,5,0)],
    resolver_e_exibir('S0 -> Sf3  [torre c-d col1, a col2, b col5]', S0, Sf3),

    Sf4 = [pos(a,0,0), pos(c,1,0), pos(d,2,0), pos(b,5,0)],
    resolver_e_exibir('S0 -> Sf4  [a col0, c col1, d col2, b col5]', S0, Sf4).


% =============================================================================
%  SITUAÇÃO 2
% =============================================================================
%
%  Sequência: S0 → S1 → S2 → S3 → S4 → S5 (meta)
%
%  S0:  c@col1(h0), a@col1(h1)[sobre c], b@col2(h0), d@col4(h0)
%    Col: 0  1  2  3  4  5  6
%              a  b     d
%              c
%
%  S1:  d vai col4 → col3
%    Col: 0  1  2  3  4  5  6
%              a  b  d
%              c
%
%  S2:  a vai col1 → col2 (sobre b)
%    Col: 0  1  2  3  4  5  6
%              c  a  d
%                 b
%  (b h0, a h1 em col2)
%
%  S3:  c→col5, b→col3, a sobre b (col3), d→col4
%    Col: 0  1  2  3  4  5  6
%                    a  d  c
%                    b
%
%  S4:  b→col2, c→col3(h0), d sobre c (col3,h1), a sobre d (col3,h2)
%    Col: 0  1  2  3  4  5  6
%                 b  a
%                    d
%                    c
%
%  S5 (meta):  d@col4(h0), c sobre d (col4,h1), a@col5(h0), b sobre a (col5,h1)
%    Col: 0  1  2  3  4  5  6
%                       c  b
%                       d  a
% =============================================================================

situacao2 :-
    write("============================================"), nl,
    write("              SITUACAO 2                    "), nl,
    write("============================================"), nl,

    S0 = [pos(c,1,0), pos(a,1,1), pos(b,2,0), pos(d,4,0)],
    S1 = [pos(c,1,0), pos(a,1,1), pos(b,2,0), pos(d,3,0)],
    S2 = [pos(c,1,0), pos(b,2,0), pos(a,2,1), pos(d,3,0)],
    S3 = [pos(b,3,0), pos(d,4,0), pos(a,3,1), pos(c,5,0)],
    S4 = [pos(b,2,0), pos(c,3,0), pos(d,3,1), pos(a,3,2)],
    S5 = [pos(d,4,0), pos(c,4,1), pos(a,5,0), pos(b,5,1)],

    resolver_e_exibir('S0 -> S1', S0, S1),
    resolver_e_exibir('S1 -> S2', S1, S2),
    resolver_e_exibir('S2 -> S3', S2, S3),
    resolver_e_exibir('S3 -> S4', S3, S4),
    resolver_e_exibir('S4 -> S5', S4, S5),
    nl, write("  ==== Plano COMPLETO ===="),
    resolver_e_exibir('S0 -> S5 (completo)', S0, S5).


% =============================================================================
%  SITUAÇÃO 3
% =============================================================================
%
%  Sequência: S0 → S1 → S2 → S3 → S4 → S5 → S6 → S7 (meta)
%
%  S0:  c@col1(h0), a@col3(h0), d@col3(h1)[sobre a], b@col5(h0)
%    Col: 0  1  2  3  4  5  6
%              c     d     b
%                    a
%
%  S1:  d desce de a e sobe sobre c (col1)   [move(d,3,1)]
%    Col: 0  1  2  3  4  5  6
%              d     a     b
%              c
%
%  S2:  d desce ao chão col0; a sobe sobre b (col5)  [move(d,1,0), move(a,3,5)]
%    Col: 0  1  2  3  4  5  6
%         d  c           a
%                        b
%
%  S3:  a libera b indo para col6; d vai de col0 para col3  [move(a,5,6), move(d,0,3)]
%    Col: 0  1  2  3  4  5  6
%              c     d     b  a
%
%  S4:  a vai para col0 (chão)  [move(a,6,0)]
%    Col: 0  1  2  3  4  5  6
%         a  c     d     b
%
%  S5:  b→col2; a sobe sobre c (col1)  [move(b,5,2), move(a,0,1)]
%    Col: 0  1  2  3  4  5  6
%              a  b  d
%              c
%
%  S6:  d avança col3→col4  [move(d,3,4)]
%    Col: 0  1  2  3  4  5  6
%              a  b     d
%              c
%
%  S7 (meta):  d avança col4→col5  [move(d,4,5)]
%    Col: 0  1  2  3  4  5  6
%              a  b        d
%              c
% =============================================================================

situacao3 :-
    write("============================================"), nl,
    write("              SITUACAO 3                    "), nl,
    write("============================================"), nl,

    S0 = [pos(c,1,0), pos(a,3,0), pos(d,3,1), pos(b,5,0)],
    S1 = [pos(c,1,0), pos(d,1,1), pos(a,3,0), pos(b,5,0)],
    S2 = [pos(d,0,0), pos(c,1,0), pos(b,5,0), pos(a,5,1)],
    S3 = [pos(c,1,0), pos(d,3,0), pos(b,5,0), pos(a,6,0)],
    S4 = [pos(a,0,0), pos(c,1,0), pos(d,3,0), pos(b,5,0)],
    S5 = [pos(c,1,0), pos(a,1,1), pos(b,2,0), pos(d,3,0)],
    S6 = [pos(c,1,0), pos(a,1,1), pos(b,2,0), pos(d,4,0)],
    S7 = [pos(c,1,0), pos(a,1,1), pos(b,2,0), pos(d,5,0)],

    resolver_e_exibir('S0 -> S1', S0, S1),
    resolver_e_exibir('S1 -> S2', S1, S2),
    resolver_e_exibir('S2 -> S3', S2, S3),
    resolver_e_exibir('S3 -> S4', S3, S4),
    resolver_e_exibir('S4 -> S5', S4, S5),
    resolver_e_exibir('S5 -> S6', S5, S6),
    resolver_e_exibir('S6 -> S7', S6, S7),
    nl, write("  ==== Plano COMPLETO ===="),
    resolver_e_exibir('S0 -> S7 (completo)', S0, S7).
