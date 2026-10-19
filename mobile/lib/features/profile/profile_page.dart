import 'package:flutter/material.dart';

import '../../core/gisam_controller.dart';
import '../../core/services/firebase_account_service.dart';
import '../../core/services/gisam_economy.dart';

class ProfilePage extends StatefulWidget {
  final GisamController controller;
  final GisamEconomy economy;
  final GisamAccount? account;
  final bool isFirebaseConfigured;
  final Future<GisamAccount> Function() onSignIn;
  final Future<void> Function() onSignOut;

  const ProfilePage({
    super.key,
    required this.controller,
    required this.economy,
    required this.account,
    required this.isFirebaseConfigured,
    required this.onSignIn,
    required this.onSignOut,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _accountActionInProgress = false;
  GisamAccount? _account;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account != widget.account) _account = widget.account;
  }

  Future<void> _accountAction() async {
    setState(() => _accountActionInProgress = true);
    try {
      if (_account == null) {
        final account = await widget.onSignIn();
        if (mounted) setState(() => _account = account);
      } else {
        await widget.onSignOut();
        if (mounted) setState(() => _account = null);
      }
    } catch (error) {
      if (mounted) {
        final signedInAccount = GisamAccountService().currentAccount;
        if (signedInAccount != null) _account = signedInAccount;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo completar la acción: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _accountActionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.controller.progress;
    final account = _account;
    final displayName = account?.displayName ?? 'Usuario invitado';
    final avatarInitial =
        displayName.isEmpty ? 'G' : displayName.substring(0, 1);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: RefreshIndicator(
        onRefresh: widget.controller.refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                foregroundImage: account?.photoUrl == null
                    ? null
                    : NetworkImage(account!.photoUrl!),
                child: Text(avatarInitial.toUpperCase(),
                    style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                displayName,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            if (account != null) ...[
              const SizedBox(height: 4),
              Center(child: Text(account.email)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed:
                  !widget.isFirebaseConfigured || _accountActionInProgress
                      ? null
                      : _accountAction,
              icon: _accountActionInProgress
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(account == null ? Icons.login : Icons.logout),
              label: Text(
                account == null
                    ? widget.isFirebaseConfigured
                        ? 'Continuar con Google'
                        : 'Configura Firebase para iniciar sesión'
                    : 'Cerrar sesión',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              account == null
                  ? 'El perfil invitado se guarda solo en este dispositivo.'
                  : 'Tu perfil y progreso están asociados a tu cuenta de Firebase.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                title: const Text('Nivel'),
                trailing: Text('${progress.level}'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('XP'),
                trailing: Text('${progress.xp} / ${progress.xpRequired}'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Monedas'),
                trailing: Text('${widget.economy.coins} 🪙'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('💧 Agua'),
                trailing: Text('${progress.water}%'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('❤️ Salud del árbol'),
                trailing: Text('${progress.health}%'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('😊 Felicidad'),
                trailing: Text('${progress.happiness}%'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
