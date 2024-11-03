CREATE TABLE bookings
(
  book_ref char(6) PRIMARY KEY,
  book_date timestamptz  NOT NULL,
  total_amount numeric(10,2) NOT NULL
);

CREATE TABLE aircrafts
(
  aircraft_code char(3) PRIMARY KEY,
  model jsonb NOT NULL,
  range integer NOT NULL
);

CREATE TABLE airports
(
  airport_code char(3) PRIMARY KEY,
  airport_name text NOT NULL,
  city text NOT NULL,
  coordinates_lon double precision NOT NULL,
  coordinates_lat double precision NOT NULL,
  timezone text NOT NULL
);

CREATE TABLE flights
(
  flight_id serial PRIMARY KEY,
  flight_no char(6) NOT NULL,
  scheduled_departure timestamptz NOT NULL,
  scheduled_arrival timestamptz NOT NULL,
  departure_airport char(3) NOT NULL REFERENCES airports(airport_code),
  arrival_airport char(3) NOT NULL REFERENCES airports(airport_code),
  status varchar(20) NOT NULL,
  aircraft_code char(3) NOT NULL REFERENCES aircrafts(aircraft_code),
  actual_departure timestamptz,
  actual_arrival timestamptz
);

CREATE TABLE tickets
(
  ticket_no char(13) PRIMARY KEY,
  book_ref char(6) NOT NULL REFERENCES bookings(book_ref),
  passenger_id varchar(20) NOT NULL,
  passenger_name text NOT NULL,
  contact_data jsonb
);

CREATE TABLE ticket_flights
(
  ticket_no char(13) REFERENCES tickets(ticket_no),
  flight_id integer REFERENCES flights(flight_id),
  fare_conditions numeric(10,2) NOT NULL,
  amount numeric(10,2) NOT NULL,
  PRIMARY KEY(ticket_no, flight_id)
);


CREATE TABLE boarding_passes
(
  ticket_no char(13) REFERENCES tickets(ticket_no),
  flight_id integer REFERENCES flights(flight_id),
  boarding_no integer NOT NULL,
  seat_no varchar(4) NOT NULL,
  PRIMARY KEY(ticket_no, flight_id),
  FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id)
);

CREATE TABLE seats
(
  aircraft_code char(3) REFERENCES aircrafts(aircraft_code),
  seat_no varchar(4) NOT NULL,
  fare_conditions varchar(10) NOT NULL,
  PRIMARY KEY (aircraft_code, seat_no)
);

create materialized view passenger_flow as(
with departure_flights as(
select departure_airport as airport_code, count(*) as departure_flights_num from flights group by departure_airport
), departure_psngr as(
select departure_airport as airport_code, count(*) as departure_psngr_num from flights join ticket_flights on flights.flight_id=ticket_flights.flight_id group by departure_airport
), arrival_flights as(
select arrival_airport as airport_code, count(*) as arrival_flights_num from flights group by arrival_airport
), arrival_psngr as(
select arrival_airport as airport_code, count(*) as arrival_psngr_num from flights join ticket_flights on flights.flight_id=ticket_flights.flight_id group by arrival_airport
)
select departure_flights.airport_code, departure_flights.departure_flights_num, departure_psngr.departure_psngr_num,
 arrival_flights.arrival_flights_num, arrival_psngr.arrival_psngr_num
 from departure_flights join departure_psngr on departure_flights.airport_code=departure_psngr.airport_code
                        join arrival_flights on departure_flights.airport_code=arrival_flights.airport_code
                        join arrival_psngr on departure_flights.airport_code=arrival_psngr.airport_code);