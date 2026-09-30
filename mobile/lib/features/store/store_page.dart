import 'package:flutter/material.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('🛒 Tienda')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Card(child: ListTile(
          leading: Icon(Icons.park),
          title: Text('Semillas del árbol'),
          subtitle: Text('Elemento cosmético del árbol de GISAM.'),
          trailing: Text('100 🪙'),
        )),
        Card(child: ListTile(
          leading: Icon(Icons.palette),
          title: Text('Personalización'),
          subtitle: Text('Futuras skins, ambientes y objetos.'),
          trailing: Text('Próximamente'),
        )),
      ],
    ),
  );
}
