import 'package:flutter/material.dart';

class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("To-do's & Tasks"),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildTaskCard('Capstone Deliverables', ['Write proposal', 'Design ERD', 'Implement features']),
          const SizedBox(height: 16),
          _buildTaskCard('Grocery Shopping', ['Buy milk', 'Buy eggs', 'Buy bread']),
        ],
      )
    );
  }

  Widget _buildTaskCard(String title, List<String> tasks) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )
            ),
            const Divider(),
            ...tasks.map((task) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(task),
              value: false,
              onChanged: (bool? value) {},
            )),
          ],
        )
      )
    );
  }
}