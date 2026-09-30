import 'package:flutter/material.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('🎮 Videojuego')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text('Tu mundo GISAM', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(child: ListTile(
          leading: Icon(Icons.stars),
          title: Text('Recompensas'),
          subtitle: Text('Las actividades de GISAM podrán desbloquear contenido del juego.'),
        )),
        Card(child: ListTile(
          leading: Icon(Icons.lock_outline),
          title: Text('Módulo en construcción'),
          subtitle: Text('Aquí conectaremos monedas, inventario y progresión.'),
        )),
      ],
    ),
  );
}
