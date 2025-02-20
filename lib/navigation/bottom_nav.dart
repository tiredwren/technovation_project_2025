import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key, this.onTabChange, required this.labels, required this.numberOfTabs, required this.icons});
  final void Function(int)? onTabChange;
  final List<String> labels;
  final int numberOfTabs;
  final List<IconData> icons;

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Color(0xFF283618),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 20),
          child: GNav(
              backgroundColor: Color(0xFF283618),
              activeColor: Color(0xFFfefae0),
              color: Color(0xFFfefae0),
              tabBackgroundColor: Color(0xFF606c38),
              gap: 5,
              padding: EdgeInsets.all(16),
              onTabChange: (value) => onTabChange!(value),
              tabs: List.generate(
              numberOfTabs,
                  (index) => GButton(
                  icon: icons[index],  // use icons from the list (more dynamic)
                  text: labels[index]
              )
          ),
        ),
        )
    );
  }
}
