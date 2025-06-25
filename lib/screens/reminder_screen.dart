import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  int waterIntake = 0;
  int waterGoal = 8;
  int medicineTaken = 0;
  int xp = 0;
  int level = 1;
  int streak = 0;
  List<Map<String, String>> medicines = [];
  DateTime? lastCompletedDay;

  final TextEditingController waterGoalController = TextEditingController();
  final TextEditingController medNameController = TextEditingController();
  TimeOfDay? medTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      waterIntake = prefs.getInt('waterIntake') ?? 0;
      waterGoal = prefs.getInt('waterGoal') ?? 8;
      medicineTaken = prefs.getInt('medicineTaken') ?? 0;
      xp = prefs.getInt('xp') ?? 0;
      level = prefs.getInt('level') ?? 1;
      streak = prefs.getInt('streak') ?? 0;
      final medList = prefs.getStringList('medicines') ?? [];
      medicines = medList.map((e) => Map<String, String>.from(Uri.splitQueryString(e))).toList();

      final lastDayString = prefs.getString('lastCompletedDay');
      if (lastDayString != null) {
        lastCompletedDay = DateTime.tryParse(lastDayString);
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('waterIntake', waterIntake);
    await prefs.setInt('waterGoal', waterGoal);
    await prefs.setInt('medicineTaken', medicineTaken);
    await prefs.setInt('xp', xp);
    await prefs.setInt('level', level);
    await prefs.setInt('streak', streak);
    await prefs.setStringList('medicines',
        medicines.map((e) => Uri(queryParameters: e).query).toList());
    if (lastCompletedDay != null) {
      await prefs.setString('lastCompletedDay', lastCompletedDay!.toIso8601String());
    }
  }

  void _addXP(int amount) {
    setState(() {
      xp += amount;
      while (xp >= level * 100) {
        xp -= level * 100;
        level++;
      }
    });
    _saveData();
  }

  void _incrementWater() {
    if (waterIntake < waterGoal) {
      setState(() => waterIntake++);
      _addXP(10);
    }
  }

  void _takeMedicine() {
    setState(() => medicineTaken++);
    _addXP(20);
  }

  void _checkStreak() {
    final now = DateTime.now();
    if (lastCompletedDay == null || now.difference(lastCompletedDay!).inDays > 1) {
      streak = 1;
    } else if (now.difference(lastCompletedDay!).inDays == 1) {
      streak++;
    }
    lastCompletedDay = now;
    _saveData();
  }

  void _markAllTasksDone() {
    _checkStreak();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔥 Streak Updated!')),
    );
  }

  void _showSetWaterGoalDialog() {
    waterGoalController.text = waterGoal.toString();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set Water Goal'),
        content: TextField(
          controller: waterGoalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Glasses per day'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => waterGoal = int.tryParse(waterGoalController.text) ?? 8);
              _saveData();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _showMedicineList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Your Medicines", style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 10),
            ...medicines.map((m) => ListTile(
              title: Text(m['name']!, style: const TextStyle(color: Colors.white)),
              subtitle: Text("Time: ${m['time']}", style: const TextStyle(color: Colors.white70)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  setState(() => medicines.remove(m));
                  _saveData();
                  Navigator.pop(context);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showAddMedicineDialog() async {
    medNameController.clear();
    medTime = null;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Medicine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: medNameController, decoration: const InputDecoration(labelText: 'Medicine Name')),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.timer),
              label: const Text('Pick Time'),
              onPressed: () async {
                TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (picked != null) setState(() => medTime = picked);
              },
            ),
            if (medTime != null) Text("Time set: ${medTime!.format(context)}")
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (medNameController.text.isNotEmpty && medTime != null) {
                medicines.add({
                  'name': medNameController.text,
                  'time': medTime!.format(context),
                });
                _saveData();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(icon, size: 30, color: Colors.white),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white70)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Health Reminder'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.water_drop),
            tooltip: 'Set Water Goal',
            onPressed: _showSetWaterGoalDialog,
          ),
          IconButton(
            icon: const Icon(Icons.medical_services),
            tooltip: 'View Medicines',
            onPressed: _showMedicineList,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)]
                : [Color(0xFFd0eaf5), Color(0xFFa5cfe8), Color(0xFF7fb1d6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
          children: [
            _buildStatCard("Water Drank", "$waterIntake / $waterGoal", Icons.water_drop, Colors.blueAccent),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _incrementWater,
              icon: const Icon(Icons.add),
              label: const Text("Drink Water"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 20),
            _buildStatCard("Medicine Taken", "$medicineTaken times", Icons.medication, Colors.deepPurple),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _takeMedicine,
              icon: const Icon(Icons.check),
              label: const Text("Take Medicine"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showAddMedicineDialog,
              icon: const Icon(Icons.add_box),
              label: const Text("Add Medicine"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 30),
            const Divider(color: Colors.white54),
            const SizedBox(height: 12),
            _buildStatCard("XP", "$xp XP", Icons.stars, Colors.green),
            const SizedBox(height: 12),
            _buildStatCard("Level", "Level $level", Icons.emoji_events, Colors.orange),
            const SizedBox(height: 12),
            _buildStatCard("Streak", "$streak days", Icons.local_fire_department, Colors.redAccent),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _markAllTasksDone,
              icon: const Icon(Icons.done_all),
              label: const Text("Mark Today's Tasks Done"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
