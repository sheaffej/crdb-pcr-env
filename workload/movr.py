import time
from typing import List
from uuid import uuid4, UUID
from random import randint
from datetime import datetime

from psycopg import Connection


class Movr:
    def __init__(self, args: dict):
        self.user_ids: List[UUID] = None
        self.vehicle_ids: List[UUID] = None

        self.user_id: UUID = None
        self.vehicle_location_id: UUID = None
        self.vehicle_id: UUID = None
        self.ride_id: UUID = None

    def setup(self, conn: Connection, id: int, total_thread_count: int):
        sql = "SELECT id FROM users"
        self.user_ids = [row[0] for row in conn.execute(sql).fetchall()]
        print(f"{len(self.user_ids)} users loaded")

        sql = "SELECT id FROM vehicles"
        self.vehicle_ids = [row[0] for row in conn.execute(sql).fetchall()]
        print(f"{len(self.vehicle_ids)} vehicles loaded")

    def _pick_user(self) -> UUID:
        return self.user_ids[randint(0, len(self.user_ids) - 1)]

    def _pick_vehicle(self) -> UUID:
        return self.vehicle_ids[randint(0, len(self.vehicle_ids) - 1)]

    # ----
    # User
    # ----
    def read_user(self, conn: Connection):
        sql = "SELECT id, city, name, address, credit_card FROM users WHERE id = %(id)s"
        row = conn.execute(sql, {'id': self._pick_user()}).fetchone()
        self.user_id = row[0]

    # -------
    # Vehicle
    # -------
    def read_vehicle(self, conn: Connection):
        sql = "SELECT id, city, owner_id, creation_time, status, current_location, ext FROM vehicles WHERE id = %(id)s"
        row = conn.execute(sql, {'id': self._pick_vehicle()}).fetchone()
        self.vehicle_id = row[0]

    def set_vehicle_in_use(self, conn: Connection):
        sql = "UPDATE vehicles SET status = %(status)s WHERE id = %(id)s RETURNING id"
        result = conn.execute(sql, {'id': self.vehicle_id, 'status': 'in_use'}).fetchone()
        return result[0]


    def set_vehicle_available(self, conn: Connection):
        sql = "UPDATE vehicles SET status = %(status)s WHERE id = %(id)s RETURNING id"
        result = conn.execute(sql, {'id': self.vehicle_id, 'status': 'available'}).fetchone()
        return result[0]

    # ----
    # Ride
    # ----
    def read_ride(self, conn: Connection):
        sql = """
            SELECT id, city, rider_id, vehicle_id, start_address, end_address, start_time, end_time, revenue
            FROM rides where id = %(id)s
            """
        conn.execute(sql, {'id': self.ride_id}).fetchone()

    def read_ride_asot(self, conn: Connection):
        sql = """
            SELECT id, city, rider_id, vehicle_id, start_address, end_address, start_time, end_time, revenue
            FROM rides AS OF SYSTEM TIME follower_read_timestamp() where id = %(id)s
            """
        conn.execute(sql, {'id': self.ride_id}).fetchone()

    def start_ride(self, conn: Connection):
        sql = """
            INSERT INTO rides (id, start_time, city, vehicle_city, rider_id, vehicle_id)
            VALUES (%(id)s, %(start_time)s, %(city)s, %(vehicle_city)s, %(rider_id)s, %(vehicle_id)s)
            """
        self.ride_id = uuid4()
        conn.execute(sql, {
            'id': self.ride_id,
            'start_time': datetime.now(),
            'city': 'San Francisco',
            'vehicle_city': 'San Francisco',
            'rider_id': self.user_id,
            'vehicle_id': self.vehicle_id
        })

    def end_ride(self, conn: Connection):
        sql = "UPDATE rides SET end_time = %(end_time)s WHERE id = %(id)s"
        conn.execute(sql, {'id': self.ride_id, 'end_time': datetime.now()})

    # ------------------------
    # Vehicle Location History
    # ------------------------
    def add_vehicle_location_history(self, conn: Connection):
        sql = """
            INSERT INTO vehicle_location_histories (id, ride_id, "timestamp", lat, long)
            VALUES (gen_random_uuid(), %(ride_id)s, %(seen_time)s, %(lat)s, %(long)s) RETURNING id
            """
        result = conn.execute(sql, {
            'ride_id': self.ride_id,
            'seen_time': datetime.now(),
            'lat': randint(-180, 180),
            'long': randint(-180, 180)
        }).fetchone()
        self.vehicle_location_id = result[0]

    def read_vehicle_last_location(self, conn: Connection):
        sql = """
            SELECT ride_id, "timestamp", city, lat, long 
            FROM vehicle_location_histories 
            WHERE id = %(id)s
            """
        conn.execute(sql, {'id':self.vehicle_location_id})

    def loop(self):
        return [
            self.read_user,
            self.read_vehicle,
            self.set_vehicle_in_use,
            self.start_ride,
            self.add_vehicle_location_history,
            self.read_vehicle_last_location,
            self.add_vehicle_location_history,
            self.read_vehicle_last_location,
            self.add_vehicle_location_history,
            self.read_vehicle_last_location,
            self.end_ride,
            self.set_vehicle_available,
            self.read_ride,
            self.read_ride_asot
        ]
