update public.room_types
set photo = regexp_replace(photo, '\.png$', '.jpg')
where photo in (
  'assets/images/rooms/deluxe.png',
  'assets/images/rooms/suite.png',
  'assets/images/rooms/presidential.png'
);
