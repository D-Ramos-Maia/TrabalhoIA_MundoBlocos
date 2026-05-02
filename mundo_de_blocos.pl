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
% Fase 1: mover d para o chão
% Fase 2: colocar a em cima de d
% Fase 3: colocar b em cima de d
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
% Fase 1: tirar a e b de cima de c
% Fase 2: colocar c em cima de d
% Fase 3: colocar a em cima de c
% Fase 4: colocar b em cima de c
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
% Fase 1: mover d para o chão
% Fase 2: colocar a em cima de c
% Fase 3: colocar b em cima de c
teste_sit3_s7(Plan) :-
    state_s0_sit1(State),
    plan(State, [on(d, floor)], Plan1),
    apply_plan(State, Plan1, MidState1),
    plan(MidState1, [on(a, c)], Plan2),
    apply_plan(MidState1, Plan2, MidState2),
    plan(MidState2, [on(b, c)], Plan3),
    append(Plan1, Plan2, Temp),
    append(Temp, Plan3, Plan).
