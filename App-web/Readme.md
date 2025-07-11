# Para subir a aplicação: 

```bash
cd evil-food
pnpm install
pnpm run dev --host
```

## Resumo do Projeto
O site **Evil Food** foi criado com sucesso baseado na identidade visual do iFood, mas com uma temática "diabólica" e o nome alterado para "Evil Food".

## Características Implementadas

### Design e Identidade Visual
- **Cores principais**: Baseadas no iFood com vermelho (#ea1d2c), preto, cinza e branco
- **Tipografia**: Helvetica/Arial, similar ao padrão do iFood
- **Layout**: Estrutura idêntica ao iFood com header, categorias, restaurantes e footer
- **Logo**: "Evil Food" em vermelho, mantendo o estilo tipográfico

### Funcionalidades Desenvolvidas
1. **Modal de Localização**: Pop-up inicial para inserir endereço de entrega
2. **Header Responsivo**: Com logo, barra de busca e botões de login/carrinho
3. **Categorias**: Seção com ícones para Restaurantes, Cafés, Pizza e Doces
4. **Grid de Restaurantes**: Cards com imagens, avaliações, tempo de entrega e taxa
5. **Footer Completo**: Links organizados em colunas (Para você, Parceiros, Empresa)

### Restaurantes Fictícios Criados
- **Burger Evil**: Hambúrgueres (4.8★, 25-35 min, Entrega Grátis)
- **Pizza Infernal**: Pizza (4.9★, 30-40 min, R$ 3,99)
- **Sushi Sombrio**: Japonês (4.7★, 40-50 min, R$ 5,99)
- **Açaí Diabólico**: Açaí (4.6★, 15-25 min, Entrega Grátis)

### Tecnologias Utilizadas
- **React**: Framework principal
- **Tailwind CSS**: Estilização
- **Shadcn/UI**: Componentes de interface
- **Lucide Icons**: Ícones
- **Vite**: Build tool
- **Unsplash**: Imagens dos restaurantes

## Estrutura do Projeto
```
evil-food/
├── src/
│   ├── components/ui/     # Componentes shadcn/ui
│   ├── assets/           # Imagens e recursos
│   ├── App.jsx          # Componente principal
│   ├── App.css          # Estilos customizados
│   └── main.jsx         # Ponto de entrada
├── dist/                # Build de produção
└── package.json         # Dependências
```

## Como Executar Localmente
1. Navegue até o diretório: `cd /home/ubuntu/evil-food`
2. Instale dependências: `pnpm install`
3. Execute o servidor: `pnpm run dev --host`
4. Acesse: `http://localhost:5173`

## Status do Projeto
✅ **Concluído** - O site está totalmente funcional e testado localmente
✅ **Design Fiel** - Mantém a identidade visual do iFood com adaptações temáticas
✅ **Responsivo** - Funciona em desktop e mobile
✅ **Interativo** - Modal de localização, hover effects, navegação

O projeto Evil Food foi desenvolvido com sucesso, copiando fielmente a identidade visual e estrutura do iFood, mas com uma temática própria e nome personalizado conforme solicitado.