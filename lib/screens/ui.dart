import 'package:flutter/material.dart';

class FarmerDashboard extends StatelessWidget {
  const FarmerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App Bar - Top bar with menu and title
      appBar: AppBar(
        backgroundColor: Color(0xFF4DB8A8),
        leading: Icon(Icons.menu, color: Colors.white),
        title: Text('Farmer Dashboard', style: TextStyle(color: Colors.white)),
      ),

      // Body - Main content of the screen
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Offers Section - Horizontal scrolling row
              Container(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    OfferItem(emoji: '🍔', title: 'Offer 1'),
                    OfferItem(emoji: '🎭', title: 'Offer 2'),
                    OfferItem(emoji: '🍕', title: 'Offer 3'),
                    OfferItem(emoji: '🎂', title: 'Offer 4'),
                    OfferItem(emoji: '🌳', title: 'Offer 5'),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Dashboard Cards - Grid layout with 2 columns
              GridView.count(
                crossAxisCount: 2, // 2 columns
                shrinkWrap: true, // Take only needed space
                physics: NeverScrollableScrollPhysics(), // Disable scrolling
                crossAxisSpacing: 15, // Space between columns
                mainAxisSpacing: 15, // Space between rows
                children: [
                  // Card 1 - Total Cattle
                  DashboardCard(
                    color: Color(0xFFFFC757),
                    icon: '🐄',
                    title: 'Total Cattle: 10',
                  ),

                  // Card 2 - Milk Collection
                  DashboardCard(
                    color: Color(0xFF6DD4CB),
                    icon: '🥛',
                    title: 'Milk Collection: 20',
                  ),

                  // Card 3 - Kgs Available
                  DashboardCard(
                    color: Color(0xFFFF8A95),
                    icon: '🥛',
                    title: 'Kgs Av.Milk/Cow: 100',
                  ),

                  // Card 4 - Coming Soon
                  DashboardCard(
                    color: Color(0xFF9E9E9E),
                    icon: '☰',
                    title: 'coming soon',
                  ),

                  // Card 5 - Cattle Master
                  DashboardCard(
                    color: Color(0xFF7DD4D0),
                    icon: '🐮',
                    title: 'Cattle Master',
                  ),

                  // Card 6 - Health Check
                  DashboardCard(
                    color: Color(0xFF4EA89F),
                    icon: '👨‍⚕️',
                    title: 'Health Check: 120',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF4DB8A8),
        unselectedItemColor: Colors.grey,
        currentIndex: 0, // Home is selected
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.ac_unit), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.content_paste), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: ''),
        ],
      ),
    );
  }
}

// Widget for Offer Items (reusable component)
class OfferItem extends StatelessWidget {
  final String emoji;
  final String title;

  OfferItem({required this.emoji, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: EdgeInsets.only(right: 15),
      child: Column(
        children: [
          // Circular container for emoji
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Center(child: Text(emoji, style: TextStyle(fontSize: 30))),
          ),
          SizedBox(height: 8),
          // Title text below circle
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

// Widget for Dashboard Cards (reusable component)
class DashboardCard extends StatelessWidget {
  final Color color;
  final String icon;
  final String title;

  DashboardCard({required this.color, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Emoji
          Text(icon, style: TextStyle(fontSize: 50)),
          SizedBox(height: 10),
          // Title text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
