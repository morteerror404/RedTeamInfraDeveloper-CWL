import { useState } from 'react'
import { Button } from '@/components/ui/button.jsx'
import { Input } from '@/components/ui/input.jsx'
import { MapPin, Search, User, ShoppingCart, Clock, Star, Utensils, Coffee, Pizza, Cake } from 'lucide-react'
import './App.css'

function App() {
  const [showLocationModal, setShowLocationModal] = useState(true)
  const [address, setAddress] = useState('')

  const categories = [
    { icon: Utensils, name: 'Restaurantes', color: 'bg-red-500' },
    { icon: Coffee, name: 'Cafés', color: 'bg-orange-500' },
    { icon: Pizza, name: 'Pizza', color: 'bg-yellow-500' },
    { icon: Cake, name: 'Doces', color: 'bg-pink-500' },
  ]

  const restaurants = [
    {
      id: 1,
      name: 'Burger Evil',
      image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300&h=200&fit=crop',
      rating: 4.8,
      deliveryTime: '25-35 min',
      category: 'Hambúrgueres',
      deliveryFee: 'Grátis'
    },
    {
      id: 2,
      name: 'Pizza Infernal',
      image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=300&h=200&fit=crop',
      rating: 4.9,
      deliveryTime: '30-40 min',
      category: 'Pizza',
      deliveryFee: 'R$ 3,99'
    },
    {
      id: 3,
      name: 'Sushi Sombrio',
      image: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=300&h=200&fit=crop',
      rating: 4.7,
      deliveryTime: '40-50 min',
      category: 'Japonês',
      deliveryFee: 'R$ 5,99'
    },
    {
      id: 4,
      name: 'Açaí Diabólico',
      image: 'https://images.unsplash.com/photo-1570197788417-0e82375c9371?w=300&h=200&fit=crop',
      rating: 4.6,
      deliveryTime: '15-25 min',
      category: 'Açaí',
      deliveryFee: 'Grátis'
    }
  ]

  const handleLocationSubmit = () => {
    if (address.trim()) {
      setShowLocationModal(false)
    }
  }

  return (
    <div className="min-h-screen bg-white">
      {/* Location Modal */}
      {showLocationModal && (
        <div className="fixed inset-0 location-modal flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-8 max-w-md w-full mx-4 shadow-2xl">
            <div className="text-center mb-6">
              <div className="delivery-illustration w-24 h-24 rounded-full mx-auto mb-4 flex items-center justify-center">
                <MapPin className="w-12 h-12 text-white" />
              </div>
              <h2 className="text-2xl font-bold text-gray-800 mb-2">
                Onde você quer receber seu pedido?
              </h2>
            </div>
            
            <div className="space-y-4">
              <div className="relative">
                <Search className="absolute left-3 top-3 w-5 h-5 text-gray-400" />
                <Input
                  type="text"
                  placeholder="Buscar endereço e número"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  className="pl-10 py-3 text-lg"
                  onKeyPress={(e) => e.key === 'Enter' && handleLocationSubmit()}
                />
              </div>
              
              <Button 
                onClick={handleLocationSubmit}
                className="w-full bg-evil-red hover:bg-evil-dark-red text-white py-3 text-lg font-semibold"
              >
                <MapPin className="w-5 h-5 mr-2" />
                Usar minha localização
              </Button>
              
              <div className="text-center">
                <p className="text-gray-600 mb-4">Já tem um endereço salvo?</p>
                <Button 
                  variant="outline" 
                  onClick={() => setShowLocationModal(false)}
                  className="border-evil-red text-evil-red hover:bg-evil-red hover:text-white"
                >
                  Entrar ou cadastrar
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <div className="flex items-center">
              <h1 className="text-2xl font-bold evil-red">Evil Food</h1>
            </div>

            {/* Search Bar */}
            <div className="flex-1 max-w-lg mx-8">
              <div className="relative">
                <Search className="absolute left-3 top-3 w-5 h-5 text-gray-400" />
                <Input
                  type="text"
                  placeholder="Busque por item ou loja"
                  className="pl-10 w-full"
                />
              </div>
            </div>

            {/* User Actions */}
            <div className="flex items-center space-x-4">
              <Button variant="ghost" size="sm">
                <User className="w-5 h-5 mr-2" />
                Entrar
              </Button>
              <Button variant="ghost" size="sm">
                <ShoppingCart className="w-5 h-5" />
              </Button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Categories */}
        <section className="mb-12">
          <h2 className="text-2xl font-bold text-gray-800 mb-6">Categorias</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {categories.map((category, index) => (
              <div
                key={index}
                className="food-card bg-white rounded-lg p-6 shadow-md cursor-pointer border hover:border-evil-red"
              >
                <div className={`w-12 h-12 ${category.color} rounded-lg flex items-center justify-center mb-4`}>
                  <category.icon className="w-6 h-6 text-white" />
                </div>
                <h3 className="font-semibold text-gray-800">{category.name}</h3>
              </div>
            ))}
          </div>
        </section>

        {/* Restaurants */}
        <section>
          <h2 className="text-2xl font-bold text-gray-800 mb-6">Restaurantes próximos</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {restaurants.map((restaurant) => (
              <div
                key={restaurant.id}
                className="food-card bg-white rounded-lg shadow-md overflow-hidden cursor-pointer"
              >
                <img
                  src={restaurant.image}
                  alt={restaurant.name}
                  className="w-full h-48 object-cover"
                />
                <div className="p-4">
                  <h3 className="font-bold text-lg text-gray-800 mb-2">{restaurant.name}</h3>
                  <p className="text-gray-600 text-sm mb-3">{restaurant.category}</p>
                  
                  <div className="flex items-center justify-between text-sm">
                    <div className="flex items-center">
                      <Star className="w-4 h-4 text-yellow-400 fill-current mr-1" />
                      <span className="font-semibold">{restaurant.rating}</span>
                    </div>
                    <div className="flex items-center text-gray-600">
                      <Clock className="w-4 h-4 mr-1" />
                      <span>{restaurant.deliveryTime}</span>
                    </div>
                  </div>
                  
                  <div className="mt-3 pt-3 border-t">
                    <span className="text-sm font-semibold evil-red">
                      Entrega: {restaurant.deliveryFee}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12 mt-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div>
              <h3 className="text-xl font-bold mb-4 evil-red">Evil Food</h3>
              <p className="text-gray-400">
                O delivery mais diabólico da cidade. Comida boa, entrega rápida.
              </p>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Para você</h4>
              <ul className="space-y-2 text-gray-400">
                <li>Aplicativo</li>
                <li>Cartão presente</li>
                <li>Promoções</li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Parceiros</h4>
              <ul className="space-y-2 text-gray-400">
                <li>Seja um parceiro</li>
                <li>Portal do parceiro</li>
                <li>Central de ajuda</li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Empresa</h4>
              <ul className="space-y-2 text-gray-400">
                <li>Sobre nós</li>
                <li>Carreiras</li>
                <li>Contato</li>
              </ul>
            </div>
          </div>
          <div className="border-t border-gray-800 mt-8 pt-8 text-center text-gray-400">
            <p>&copy; 2025 Evil Food. Todos os direitos reservados.</p>
          </div>
        </div>
      </footer>
    </div>
  )
}

export default App

