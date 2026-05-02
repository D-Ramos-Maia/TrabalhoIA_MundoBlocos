# Inteligência Artificial - 1º Trabalho Prático
## Representação do Conhecimento para Gerar Planejador que Empilha Blocos de Diferentes Dimensões

**Integrantes:**
* Beatriz Augusta Coelho Bezerra
* Daniel Ramos Maia
* Victor Lima Frazão

**Instituição:** Instituto de Computação - UFAM  
**Professor:** Edjard Mota (2026)

---

## Como executar o código  

O código foi pensado para ser executado via Swish-prolog (https://swish.swi-prolog.org/), para o executar basta apenas executar os seguintes comandos no terminal.

### Situação 1

```prolog
% Executar situação 1
teste_sit1_sf1(Plan).
````

### Situação 2

```prolog
% Executar situação 2
teste_sit2_s5(Plan).
```

### Situação 3

```prolog
% Executar situação 3
teste_sit3_s7(Plan).
```

## Questão 1 - Descrição do Problema em Linguagem Natural

O problema consiste no empilhamento de blocos retangulares que possuem diferentes larguras, mas todos com a mesma altura unitária (altura = 1). Os blocos são identificados pelas letras **a**, **b**, **c** e **d**, com as seguintes larguras:

| Bloco | Largura | Posições Ocupadas |
|---|---|---|
| a | 1 | 1 |
| b | 1 | 1 |
| c | 2 | 2 |
| d | 3 | 3 |

Os blocos são posicionados sobre uma superfície plana (mesa) com 7 posições horizontais numeradas de **0 a 6**. Cada bloco ocupa uma sequência contínua de posições horizontais correspondente à sua largura, e pode ser empilhado sobre outros blocos, desde que respeite as regras de estabilidade física.

O estado inicial (**S0**) das Situações 1 e 3 é:
- **a:** começa em 3, termina em 4
- **b:** começa em 5, termina em 6
- **c:** começa em 0, termina em 2
- **d:** começa em 3, termina em 6 (está em cima de a e b)

O estado inicial (**S0**) da Situação 2 é:
- **a:** começa em 0, termina em 1 (está em cima de c)
- **b:** começa em 1, termina em 2 (está em cima de c)
- **c:** começa em 0, termina em 2
- **d:** começa em 3, termina em 6

O objetivo em cada situação é encontrar uma sequência de movimentos `move(B, Pi, Pj)` que move o bloco **B** da posição **Pi** para a posição **Pj**, transformando o estado inicial em uma configuração final desejada.

As regras que o mundo deve respeitar são:
- Um bloco só pode ser movido se não houver nenhum outro bloco em cima dele
- Um bloco só pode ser colocado em uma posição se todas as posições que ele ocupa estiverem livres
- Um bloco só pode ser empilhado sobre outro se houver suporte suficiente abaixo dele
- Os blocos não podem ultrapassar os limites da mesa (posições 0 a 6)
- Um bloco mais largo não pode ficar em cima de um mais estreito sem suporte adequado

---

## Questão 2 - Definição dos Conceitos

### `block(B, W)` — Cadastro dos blocos
Define que o bloco **B** tem largura **W**.

```prolog
block(a, 1).
block(b, 1).
block(c, 2).
block(d, 3).
```

### `on(B, X)` — Sobreposição
Define que o bloco **B** está em cima de **X**, onde X pode ser outro bloco ou o chão (`floor`).

```prolog
on(d, a).      % d está em cima de a
on(a, floor).  % a está no chão
on(c, floor).  % c está no chão
on(b, floor).  % b está no chão
```

### `position(B, X1, X2)` — Posição horizontal
Define que o bloco **B** ocupa da posição **X1** até **X2** na mesa.

```prolog
position(a, 3, 4).
position(b, 5, 6).
position(c, 0, 2).
position(d, 3, 6).
```

### `clear(B)` — Bloco livre
Um bloco está livre quando não tem nenhum outro bloco em cima dele. Só blocos livres podem ser movidos.

```prolog
clear(c).
clear(d).
clear(b).
```

### `stable(B1, B2)` — Estabilidade
Define se o bloco **B1** pode ficar estável em cima de **B2**. O bloco de cima não pode ser mais largo que o bloco de baixo.

```prolog
stable(B1, B2) :-
    block(B1, W1),
    block(B2, W2),
    W1 =< W2.
```

### `center(B, C)` — Centro geométrico ⭐ Ponto Extra
Define o centro geométrico do bloco **B**.

```prolog
center(B, C) :-
    block(B, W),
    position(B, X1, _),
    C is X1 + W / 2.
```

### `balanced(B1, B2)` — Equilíbrio por centro geométrico ⭐ Ponto Extra
Um bloco **B1** está em equilíbrio sobre **B2** quando o centro de **B1** está dentro dos limites horizontais de **B2**.

```prolog
balanced(B1, B2) :-
    center(B1, C1),
    position(B2, X1, X2),
    C1 >= X1,
    C1 =< X2.
```

### Estado do mundo como lista
O estado completo do **S0** da Situação 1:

```prolog
s0([
    on(a, floor),    position(a, 3, 4),
    on(b, floor),    position(b, 5, 6),
    on(c, floor),    position(c, 0, 2),
    on(d, a),        position(d, 3, 6),
    clear(c),
    clear(d),
    clear(b)
]).
```

---

## Questão 3 - Representação das Ações

A ação principal do planejador é mover um bloco de uma posição para outra, definida como `move(B, Pi, Pj)`, onde:
- **B** é o bloco a ser movido
- **Pi** é a posição de origem
- **Pj** é a posição de destino

### Pré-condições

```prolog
can(move(B, Pi, Pj), [clear(B), on(B, Pi), position(B, Xi, Xf), 
                       free_space(Yj, Yf), stable(B, Pj)]).
```

- `clear(B)` — não há nenhum bloco em cima de B
- `on(B, Pi)` — B está na posição de origem Pi
- `position(B, Xi, Xf)` — posição horizontal atual de B
- `free_space(Yj, Yf)` — todas as posições de destino estão livres
- `stable(B, Pj)` — B ficará estável na posição de destino

### Efeitos positivos

```prolog
adds(move(B, Pi, Pj), [on(B, Pj), clear(Pi)]).
```

### Efeitos negativos

```prolog
deletes(move(B, Pi, Pj), [on(B, Pi), clear(Pj)]).
```

### Regra de estabilidade

```prolog
stable(B1, B2) :- 
    block(B1, W1), 
    block(B2, W2), 
    W1 =< W2.
```

### Centro geométrico ⭐ Ponto Extra

```prolog
center(B, C) :- 
    position(B, X1, X2), 
    C is (X1 + X2) / 2.

balanced(B1, B2) :- 
    center(B1, C1), 
    position(B2, X1, X2), 
    C1 >= X1, 
    C1 =< X2.
```

---

## Questão 4 - Restrições

### 4.1 Restrições em Linguagem Natural

- Um bloco só pode ser movido se estiver livre
- A posição de destino deve estar dentro dos limites da mesa (0 a 6)
- Todas as posições que o bloco ocupará no destino devem estar livres
- O bloco de cima não pode ser mais largo que o bloco de baixo
- Um bloco não pode ser movido para o lugar onde já está
- Dois blocos não podem ocupar o mesmo lugar

### 4.2 Código Base do Bratko (Capítulo 17)

```prolog
plan(State, Goals, []) :-
    satisfied(State, Goals).

plan(State, Goals, Plan) :-
    append(PrePlan, [Action], Plan),
    select(State, Goals, Goal),
    achieves(Action, Goal),
    can(Action, Condition),
    preserves(Action, Goals),
    regress(Goals, Action, RegressedGoals),
    plan(State, RegressedGoals, PrePlan).

satisfied(State, Goals) :-
    delete_all(Goals, State, []).

select(_, Goals, Goal) :-
    member(Goal, Goals).

achieves(Action, Goal) :-
    adds(Action, Goals),
    member(Goal, Goals).

preserves(Action, Goals) :-
    deletes(Action, Relations),
    \+ (member(Goal, Relations),
        member(Goal, Goals)).

regress(Goals, Action, RegressedGoals) :-
    adds(Action, NewRelations),
    delete_all(Goals, NewRelations, RestGoals),
    can(Action, Condition),
    addnew(Condition, RestGoals, RegressedGoals).

addnew([], L, L).
addnew([Goal|_], Goals, _) :-
    impossible(Goal, Goals), !,
    fail.
addnew([X|L1], L2, L3) :-
    member(X, L2), !,
    addnew(L1, L2, L3).
addnew([X|L1], L2, [X|L3]) :-
    addnew(L1, L2, L3).

delete_all([], _, []).
delete_all([X|L1], L2, Diff) :-
    member(X, L2), !,
    delete_all(L1, L2, Diff).
delete_all([X|L1], L2, [X|Diff]) :-
    delete_all(L1, L2, Diff).
```

### 4.3 Implementação Completa Adaptada

```prolog
% =================================================================
% DECLARAÇÕES
% =================================================================
:- discontiguous can/2.
:- discontiguous adds/2.
:- discontiguous deletes/2.

% =================================================================
% 1. DEFINIÇÃO DO MUNDO
% =================================================================
block(a, 1).
block(b, 1).
block(c, 2).
block(d, 3).

object(X) :- block(X, _).
object(floor).

% =================================================================
% 2. ESTABILIDADE
% =================================================================
stable(B1, B2) :-
    block(B1, W1),
    block(B2, W2),
    W1 =< W2.

% =================================================================
% 3. AÇÕES
% =================================================================
can(move(B, Pi, floor), [clear(B), on(B, Pi)]) :-
    block(B, _),
    block(Pi, _),
    Pi \== floor,
    Pi \== B.

can(move(B, floor, floor), [clear(B), on(B, floor)]) :-
    block(B, _).

can(move(B1, Pi, B2), [clear(B1), clear(B2), on(B1, Pi)]) :-
    block(B1, _),
    block(B2, _),
    block(Pi, _),
    B1 \== B2,
    B1 \== Pi,
    Pi \== B2,
    stable(B1, B2).

can(move(B1, floor, B2), [clear(B1), clear(B2), on(B1, floor)]) :-
    block(B1, _),
    block(B2, _),
    B1 \== B2,
    stable(B1, B2).

adds(move(B, Pi, Pj), [on(B, Pj), clear(Pi)]) :-
    object(Pi),
    object(Pj).

deletes(move(B, Pi, Pj), [on(B, Pi), clear(Pj)]) :-
    object(Pi),
    object(Pj).

% =================================================================
% 4. IMPOSSIBILIDADES
% =================================================================
impossible(on(X, X), _).
impossible(on(X, Y), Goals) :-
    member(on(X, Y1), Goals), Y1 \== Y
    ;
    member(on(X1, Y), Goals), X1 \== X.

% =================================================================
% 5. PLANEJADOR
% =================================================================
plan(State, Goals, Plan) :-
    between(0, 6, MaxDepth),
    plan(State, Goals, [], Plan, MaxDepth).

plan(State, Goals, _, [], _) :-
    satisfied(State, Goals).

plan(State, Goals, Visited, [Action|Rest], MaxDepth) :-
    MaxDepth > 0,
    NextDepth is MaxDepth - 1,
    seleciona(State, Goals, Goal),
    achieves(Action, Goal),
    can(Action, _),
    preserves(Action, Goals),
    \+ member(Action, Visited),
    regress(Goals, Action, RegressedGoals),
    plan(State, RegressedGoals, [Action|Visited], Rest, NextDepth).

satisfied(State, Goals) :-
    delete_all(Goals, State, []).

seleciona(_, Goals, Goal) :-
    member(Goal, Goals).

achieves(Action, Goal) :-
    adds(Action, Goals),
    member(Goal, Goals).

preserves(Action, Goals) :-
    deletes(Action, Relations),
    \+ (member(Goal, Relations),
        member(Goal, Goals)).

regress(Goals, Action, RegressedGoals) :-
    adds(Action, NewRelations),
    delete_all(Goals, NewRelations, RestGoals),
    can(Action, Condition),
    addnew(Condition, RestGoals, RegressedGoals).

addnew([], L, L).
addnew([Goal|_], Goals, _) :-
    impossible(Goal, Goals), !,
    fail.
addnew([X|L1], L2, L3) :-
    member(X, L2), !,
    addnew(L1, L2, L3).
addnew([X|L1], L2, [X|L3]) :-
    addnew(L1, L2, L3).

delete_all([], _, []).
delete_all([X|L1], L2, Diff) :-
    member(X, L2), !,
    delete_all(L1, L2, Diff).
delete_all([X|L1], L2, [X|Diff]) :-
    delete_all(L1, L2, Diff).

% Planejador em duas fases
plan_two_phase(State, Goals1, Goals2, Plan) :-
    plan(State, Goals1, Plan1),
    apply_plan(State, Plan1, MidState),
    plan(MidState, Goals2, Plan2),
    append(Plan1, Plan2, Plan).

% Aplica um plano a um estado
apply_plan(State, [], State).
apply_plan(State, [move(B, Pi, Pj)|Rest], FinalState) :-
    adds(move(B, Pi, Pj), Add),
    deletes(move(B, Pi, Pj), Del),
    delete_all(State, Del, Temp),
    append(Add, Temp, NewState),
    apply_plan(NewState, Rest, FinalState).

% =================================================================
% 6. ESTADOS
% =================================================================
state_s0_sit1([
    on(a, floor), on(b, floor),
    on(c, floor), on(d, a),
    clear(c), clear(d), clear(b)
]).

state_s0_sit2([
    on(a, c), on(b, c),
    on(c, floor), on(d, floor),
    clear(a), clear(b), clear(d)
]).

% =================================================================
% 7. TESTES
% =================================================================

% Situação 1 - S0 até Sf1
teste_sit1_sf1(Plan) :-
    state_s0_sit1(State),
    plan(State, [on(d, floor)], Plan1),
    apply_plan(State, Plan1, MidState1),
    plan(MidState1, [on(a, d)], Plan2),
    apply_plan(MidState1, Plan2, MidState2),
    plan(MidState2, [on(b, d)], Plan3),
    append(Plan1, Plan2, Temp),
    append(Temp, Plan3, Plan).

% Situação 2 - S0 até S5
teste_sit2_s5(Plan) :-
    state_s0_sit2(State),
    plan(State, [on(a, floor)], Plan1),
    apply_plan(State, Plan1, MidState1),
    plan(MidState1, [on(b, floor)], Plan2),
    apply_plan(MidState1, Plan2, MidState2),
    plan(MidState2, [on(c, d)], Plan3),
    apply_plan(MidState2, Plan3, MidState3),
    plan(MidState3, [on(a, c)], Plan4),
    apply_plan(MidState3, Plan4, MidState4),
    plan(MidState4, [on(b, c)], Plan5),
    append(Plan1, Plan2, Temp1),
    append(Temp1, Plan3, Temp2),
    append(Temp2, Plan4, Temp3),
    append(Temp3, Plan5, Plan).

% Situação 3 - S0 até S7
teste_sit3_s7(Plan) :-
    state_s0_sit1(State),
    plan(State, [on(d, floor)], Plan1),
    apply_plan(State, Plan1, MidState1),
    plan(MidState1, [on(a, c)], Plan2),
    apply_plan(MidState1, Plan2, MidState2),
    plan(MidState2, [on(b, c)], Plan3),
    append(Plan1, Plan2, Temp),
    append(Temp, Plan3, Plan).
```

---

## Questão 5 - Comparação entre Planos Manuais e Gerados pelo Código

### Situação 1 — S0 até Sf1

**Plano Manual:**

move(d, a, floor)
move(a, floor, d)
move(b, floor, d)
move(c, floor, a)


**Plano Gerado pelo Código:**

move(d, a, floor)
move(a, floor, d)
move(b, floor, d)
move(a, d, c)


**Análise:** Os três primeiros passos são idênticos. A diferença está no quarto passo — o aluno colocou `c` em cima de `a`, enquanto o planejador colocou `a` em cima de `c`. Ambas as soluções são válidas.

---

### Situação 2 — S0 até S5

**Plano Manual:**

move(a, c, floor)
move(b, c, floor)
move(c, floor, d)
move(a, floor, c)
move(b, floor, c)


**Plano Gerado pelo Código:**

move(a, c, floor)
move(b, c, floor)
move(c, floor, d)
move(a, floor, c)
move(b, floor, c)
move(a, c, floor)


**Análise:** Os cinco primeiros passos são idênticos. O planejador gerou um sexto passo redundante, característica conhecida do goal regression planning.

---

### Situação 3 — S0 até S7

**Plano Manual:**

move(d, a, floor)
move(a, floor, c)
move(b, floor, c)


**Plano Gerado pelo Código:**

move(d, a, floor)
move(a, floor, c)
move(b, floor, c)
move(a, c, d)


**Análise:** Os três primeiros passos são idênticos. O planejador gerou um quarto passo extra desnecessário.

---

### Conclusão Geral

| Situação | Passos Manual | Passos Código | Passos Extras |
|---|---|---|---|
| Sit 1 S0→Sf1 | 4 | 4 | 0 |
| Sit 2 S0→S5 | 5 | 6 | 1 |
| Sit 3 S0→S7 | 3 | 4 | 1 |

A principal diferença entre os planos manuais e os planos gerados pelo código é que o planejador por goal regression às vezes gera passos extras desnecessários. Os planos manuais são mais enxutos porque a equipe pensou de frente para trás, identificando diretamente a sequência mínima de ações necessárias. Já o planejador automático garante que todos os objetivos sejam satisfeitos, mas sem otimizar o número de passos.
