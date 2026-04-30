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








