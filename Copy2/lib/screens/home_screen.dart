import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text("Healthcare AI"),
        backgroundColor: Color(0xFF6C63FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Enter Your Symptoms",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            TextField(
              decoration: InputDecoration(
                hintText: "e.g fever, cough",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            Text(
              "Enter Budget",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "e.g 500",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6C63FF),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () {
                  // NEXT: connect API
                },
                child: Text("Get Recommendation"),
              ),
            )
          ],
        ),
      ),
    );
  }
}