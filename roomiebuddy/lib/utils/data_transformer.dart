int priorityToInt(String? priority) {
  switch (priority) {
    case 'Low':
      return 0;
    case 'Medium':
      return 1;
    case 'High':
      return 2;
    default:
      return 0;
  }
} 

String priorityToString(int priority) {
  switch (priority) {
    case 0: return 'Low';
    case 1: return 'Medium';
    case 2: return 'High';
    default: return 'Unknown';
  }
}