# Inteligência Artificial - 1º Trabalho Prático
## Representação do Conhecimento para Gerar Planejador que Empilha Blocos de Diferentes Dimensões

**Integrantes:**
* Beatriz Augusta Coelho Bezerra
* Daniel Ramos Maia
* Victor Lima Frazão

**Instituição:** Instituto de Computação - UFAM  
**Professor:** Edjard Mota (2026)

---

## 1. Representação do Conhecimento

### Linguagem Natural
Neste trabalho, abordamos o problema do Mundo dos Blocos onde os blocos possuem comprimentos variáveis, mas mantêm a mesma altura. A representação precisa considerar não apenas o que está "sobre" o quê, mas também o espaço horizontal ocupado (coordenadas ou largura) para garantir o equilíbrio e a viabilidade do empilhamento.

### Uso de IA Generativa
Utilizamos a IA **Claude** para auxiliar na tradução das restrições de lógica de primeira ordem para código **Prolog**, visando resolver as situações de planejamento propostas.

---

## 2. Raciocínio e Planejamento

O objetivo central foi transformar a descrição do cenário e as regras de física/empilhamento (linguagem natural) em predicados lógicos que a máquina possa processar via *goal regression planning*.

---

## 3. Execução do Código 

Abaixo estão os comandos/predicados para executar as resoluções de cada cenário no Prolog:

### Situação 1
```prolog
% Comando para executar a situação 1
situacao1.
```
### Situação 2
```prolog
% Comando para executar a situação 2
situacao2.
```

### Situação 3
```prolog
% Comando para executar a situação 3
situacao3.
```

## 4. Explicação detalhada ponto a ponto

Este código em Prolog implementa um Planejador Espacial para o problema do "Mundo dos Blocos". Ele utiliza uma técnica de busca chamada BFS (Busca em Largura) para encontrar o caminho mais curto entre uma configuração inicial de blocos e uma configuração final.

### 1. Modelagem do Mundo (Estrutura de Dados)
O código não usa uma matriz fixa; ele usa uma Lista de Factos Dinâmicos.

* `pos(Bloco, Coluna, Altura)`: Isto é um objeto lógico. Quando o código vê `pos(a, 3, 0)`, ele entende que o bloco `a` está na base da coluna 3.

* *Flexibilidade*: Diferente de modelos que usam apenas `on(A, B)`, esta estrutura permite que o bloco esteja em qualquer lugar horizontalmente (0 a 6), atendendo ao requisito de "espaços horizontais" do seu professor.

## 2. A Lógica de Transição (As Regras da Física)

Aqui é onde o código decide se um movimento é "legal" ou não:

* *Verificação de Obstáculos (`topo_livre`)*:

```prolog
\+ (member(pos(_, Col, AltX), Estado), AltX > Alt)
```
Este trecho é uma *Negação por Falha*. Ele diz: "Procure qualquer bloco na mesma coluna (`Col`) que tenha uma altura (`AltX`) maior que a minha (`Alt`). Se não encontrar nenhum, o topo está livre."

* *Cálculo Dinâmico de Empilhamento (`altura_coluna`)*:
Antes de mover o bloco para a coluna `Pj`, o código usa `findall` para contar quantos blocos já existem lá. Se houver 2 blocos, a nova altura será 2 (os índices são 0, 1, 2). Isso simula a gravidade: o bloco sempre "cai" na posição mais baixa disponível daquela coluna.

* *Manipulação da Lista (`aplicar_move`)*:
O predicado `select(pos(B, Pi, _), Estado, Temp)` é crucial. Ele remove a posição antiga do bloco da lista e guarda o resto do mundo em `Temp`. Depois, o código adiciona a nova posição: `[pos(B, Pj, NovaAlt) | Temp]`.

## 3. O Mecanismo de Inteligência (BFS - Busca em Largura)

O "cérebro" do planeador é o algoritmo BFS. Ele funciona como uma onda se espalhando:

1. *Fila de Exploração*: O código mantém uma lista de caminhos possíveis. *Exemplo*: `[[EstadoInicial, []]]`.

2. *Expansão*: Ele pega o primeiro estado da fila e tenta todos os movimentos possíveis (bloco A para col 0, A para col 1... bloco B para col 0, etc.).

3. *Prevenção de Ciclos (`ja_na_fila`)*: Se um movimento resulta num estado que o código já viu antes, ele descarta esse caminho. Sem isto, o robô ficaria movendo o bloco `a` da coluna 1 para a 2 e de volta para a 1 eternamente.

4. *Garantia de Curto Caminho*: Por ser BFS, ele testa todos os planos de 1 movimento, depois todos os de 2, depois todos os de 3. Assim que encontrar o objetivo (`mesmo_estado`), ele garante que aquele é o plano com o menor número de passos.

##4. Execução das Situações (Os Testes)

No final do código, as funções `situacao1`, `2` e `3` definem o *Estado Inicial (S0)* e o *Estado Objetivo (Sf)*.
