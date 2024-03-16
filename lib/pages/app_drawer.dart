import 'package:flutter/material.dart';
import 'package:mymap/widgets/drawer_list_tile.dart';

class AppDrawer extends StatelessWidget {
  final void Function()? onProfileTap;
  final void Function()? onSignOut;

  const AppDrawer({super.key, this.onProfileTap, this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      //backgroundColor: Colors.lightBlueAccent,
      backgroundColor: const Color(0xFFDAE2FF),
      width: 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const DrawerHeader(
                child: Icon(
                  Icons.person,
                  //color: Colors.white,
                  size: 64,
                ),
              ),
              DrawerListTile(
                icon: Icons.home,
                text: "H O M E",
                onTap: () => Navigator.pop(context),
              ),
              DrawerListTile(
                icon: const IconData(0xe62a, fontFamily: 'MaterialIcons'),
                text: "P R O F I L E",
                onTap: onProfileTap,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: DrawerListTile(
              icon: Icons.logout,
              text: "L O G O U T",
              onTap: onSignOut,
            ),
          ),
        ],
      ),
    );
  }
}
