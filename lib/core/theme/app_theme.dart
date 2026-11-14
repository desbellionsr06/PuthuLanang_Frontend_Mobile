import 'package:flutter/material.dart';

const brown = Color(0xFF17110C);
const brown2 = Color(0xFF241913);
const border = Color(0xFF3F2D23);
const cream = Color(0xFFF8F4EC);
const gold = Color.fromARGB(255, 230, 150, 22);
const green = Color(0xFF2E7D32);
const muted = Color(0xFFC5B8A8);

String rupiah(int n) {
  return 'Rp ${n.toString().replaceAllMapped(
        RegExp(r'(?=(\d{3})+(?!\d))'),
        (m) => '.',
      )}';
}
