-- DB Assignmnet 4
-- Christina DiMaggio
-- November 4 2024

set SQL_SAFE_UPDATES=0;
use examples;
 
-- Contraints, PK, FK and UQ

ALTER TABLE actor 
ADD PRIMARY KEY (actor_id);

ALTER TABLE address 
ADD PRIMARY KEY (address_id),
ADD CONSTRAINT fk_address_city FOREIGN KEY (city_id) REFERENCES city(city_id);

ALTER TABLE category 
ADD PRIMARY KEY (category_id),
ADD CONSTRAINT chk_category_name CHECK (name IN 
('Animation', 'Comedy', 'Family', 'Foreign', 'Sci-Fi', 'Travel', 'Children', 'Drama', 'Horror', 'Action', 'Classics', 'Games', 
'New', 'Documentary', 'Sports', 'Music'));

ALTER TABLE city 
ADD PRIMARY KEY (city_id),
ADD CONSTRAINT fk_city_country FOREIGN KEY (country_id) REFERENCES country(country_id);

ALTER TABLE country
ADD PRIMARY KEY (country_id);

ALTER TABLE customer
ADD PRIMARY KEY (customer_id),
ADD CONSTRAINT fk_customer_store FOREIGN KEY (store_id) REFERENCES store(store_id),
ADD CONSTRAINT fk_customer_address FOREIGN KEY (address_id) REFERENCES address(address_id),
ADD CONSTRAINT chk_customer_active CHECK (active IN (0, 1));

ALTER TABLE film
ADD PRIMARY KEY (film_id),
ADD CONSTRAINT fk_film_language FOREIGN KEY (language_id) REFERENCES language(language_id),
ADD CONSTRAINT chk_special_features CHECK (special_features IN 
('Behind the Scenes', 'Commentaries', 'Deleted Scenes', 'Trailers')),
ADD CONSTRAINT chk_rental_rate_range CHECK (rental_rate >= 0.99 AND rental_rate <= 6.99),
ADD CONSTRAINT chk_length_range CHECK (length >= 30 AND length <= 200),
ADD CONSTRAINT chk_film_rating CHECK (rating IN ('PG', 'G', 'NC-17', 'PG-13', 'R')),
ADD CONSTRAINT chk_replacement_cost_range CHECK (replacement_cost >= 5.00 AND replacement_cost <= 100.00);

ALTER TABLE film_actor
ADD PRIMARY KEY (actor_id, film_id),
ADD CONSTRAINT fk_film_actor_actor FOREIGN KEY (actor_id) REFERENCES actor(actor_id),
ADD CONSTRAINT fk_film_actor_film FOREIGN KEY (film_id) REFERENCES film(film_id);

ALTER TABLE rental
ADD PRIMARY KEY (rental_id),
ADD CONSTRAINT fk_inventory_id FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id),
ADD CONSTRAINT fk_customer_id FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
ADD CONSTRAINT fk_rental_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
ADD CONSTRAINT uq_rental_unique UNIQUE (customer_id, inventory_id, rental_date),
MODIFY COLUMN return_date DATETIME,
MODIFY COLUMN rental_date DATETIME,
ADD CONSTRAINT chk_rental_date CHECK (rental_date <= GETDATE()),
ADD CONSTRAINT chk_return_date CHECK (return_date <= GETDATE());

ALTER TABLE staff
ADD PRIMARY KEY (staff_id),
ADD CONSTRAINT fk_staff_address FOREIGN KEY (address_id) REFERENCES address(address_id),
ADD CONSTRAINT fk_staff_store FOREIGN KEY (store_id) REFERENCES store(store_id),
ADD CONSTRAINT chk_staff_active CHECK (active IN (0, 1));

ALTER TABLE store
ADD PRIMARY KEY (store_id),
ADD CONSTRAINT fk_store_address FOREIGN KEY (address_id) REFERENCES address(address_id);

ALTER TABLE film_category
ADD PRIMARY KEY (film_id, category_id),
ADD CONSTRAINT fk_film_category_film FOREIGN KEY (category_id) REFERENCES category(category_id),
ADD CONSTRAINT fk_film_category_category FOREIGN KEY (film_id) REFERENCES film(film_id);

ALTER TABLE inventory
ADD PRIMARY KEY (inventory_id),
ADD CONSTRAINT fk_inventory_film FOREIGN KEY (film_id) REFERENCES film(film_id),
ADD CONSTRAINT fk_inventory_store FOREIGN KEY (store_id) REFERENCES store(store_id);

ALTER TABLE language
ADD PRIMARY KEY (language_id);

ALTER TABLE payment
ADD PRIMARY KEY (payment_id),
ADD CONSTRAINT fk_payment_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
ADD CONSTRAINT fk_payment_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
ADD CONSTRAINT fk_payment_rental FOREIGN KEY (rental_id) REFERENCES rental(rental_id),
ADD CONSTRAINT chk_amount CHECK (amount >= 0),
MODIFY COLUMN payment_date DATETIME,
ADD CONSTRAINT chk_payment_date CHECK (payment_date <= GETDATE());


-- 1. What is the average length of films in each category? List the results in alphabetic order of categories.
		-- need to combine film with film_category and category
			-- chain broken if there is no link with primary keys, everything has to be conneceted
					-- film_category and category have foreign keys 
		-- need category name
        -- need to calculate average length of film
SELECT c.name AS category_name, AVG(f.length) AS avg_length -- alias
FROM film f -- universal set
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name -- filter, category name calculate average film length
ORDER BY c.name;  -- how data is ordered in grid, alphabetical

-- 2. Which categories have the longest and shortest average film lengths?
		-- need to create CTE of average film lengths 
			-- need to combine film with film_category and category
				-- chain broken if there is no link with primary keys, everything has to be connected
					-- film_category and category have foreign keys 
				-- need category name
				-- need to calculate average length of film
		-- select to use CTE and determine longest and shortest average film lengths
		
WITH avg_film_lengths AS ( -- create CTE
    SELECT c.name AS category_name, AVG(f.length) AS avg_length -- alias
    FROM film f -- universal set
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    GROUP BY c.name -- filter, category name calculate average film length
)
SELECT category_name, avg_length
FROM avg_film_lengths
WHERE avg_length = (SELECT MAX(avg_length) FROM avg_film_lengths)
   OR avg_length = (SELECT MIN(avg_length) FROM avg_film_lengths); -- only returns shortest and longest average film lengths
   
-- 3. Which customers have rented action but not comedy or classic movies?
		-- need to combine customer with rental, inventory, film, film_category, and category FIRST, filter to only show action
			-- chain broken if there is no link with primary keys, everything has to be conneceted
					-- rental, inventory, film, film_category, and category have foreign keys 
        -- SECOND need to combine customer with rental, inventory, film, film_category, and category to filter only showing comedy and classic
			-- chain broken if there is no link with primary keys, everything has to be conneceted
					-- rental, inventory, film, film_category, and category have foreign keys 

SELECT c.customer_id, c.first_name, c.last_name
FROM customer c -- universal set
JOIN rental r ON c.customer_id = r.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category cat ON fc.category_id = cat.category_id
WHERE cat.name = 'Action' -- filter
AND c.customer_id NOT IN ( -- will take all customers that bought action movies but NOT comedy or classic movies
    SELECT c2.customer_id
    FROM customer c2 -- universal set
    JOIN rental r2 ON c2.customer_id = r2.customer_id
    JOIN inventory i2 ON r2.inventory_id = i2.inventory_id
    JOIN film f2 ON i2.film_id = f2.film_id
    JOIN film_category fc2 ON f2.film_id = fc2.film_id
    JOIN category cat2 ON fc2.category_id = cat2.category_id
    WHERE cat2.name IN ('Comedy', 'Classic') -- filter
)
GROUP BY c.customer_id, c.first_name, c.last_name -- filter, customer's id and their name, first and last
ORDER BY c.first_name;  -- how data is ordered in grid, alphabetical 

-- 4. Which actor has appeared in the most English-language movies?
		-- need to create CTE of most English-language movies 
			-- need to combine actor with film_actor, film, and language
				-- chain broken if there is no link with primary keys, everything has to be connected
					-- film_actor, film, and language have foreign keys 
				-- need actor name
				-- need to determine which actors have appeared in English-language movies 
		-- select to use CTE and determine the actor that has appeared the most in English-language movies
		
WITH english_movie_actors AS ( -- create CTE
    SELECT a.actor_id, a.first_name, a.last_name, COUNT(f.film_id) AS movie_count -- alias
    FROM actor a -- universal set
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    JOIN film f ON fa.film_id = f.film_id
    JOIN language l ON f.language_id = l.language_id
    WHERE l.name = 'English' -- filter
    GROUP BY a.actor_id, a.first_name, a.last_name -- filter, actor's who have appeared in English-language movies
)
SELECT actor_id, first_name, last_name
FROM english_movie_actors
WHERE movie_count = (SELECT MAX(movie_count) FROM english_movie_actors); -- only returns the actor who has appeared in the most English-Language movies

-- 5. How many distinct movies were rented for exactly 10 days from the store where Mike works?
		-- need to combine rental with inventory, store, staff, and film
			-- chain broken if there is no link with primary keys, everything has to be conneceted
					-- inventory, store, staff, and film have foreign keys 
		-- need count of films
        -- need to calculate days movie was rented for
        -- need to ensure movie rented for 10 days was at Mikes store
SELECT COUNT(DISTINCT f.film_id) AS movies_rented -- alias and counts unqiue films
FROM rental r -- universal set
JOIN inventory inv ON r.inventory_id = inv.inventory_id
JOIN store s ON inv.store_id = s.store_id
JOIN staff st ON s.store_id = st.store_id
JOIN film f ON inv.film_id = f.film_id
JOIN (
    SELECT rental_id, DATEDIFF(return_date, rental_date) AS rental_duration -- calculate how many days movie was rented for
    FROM rental
) rd ON r.rental_id = rd.rental_id
WHERE st.first_name = 'Mike' AND rd.rental_duration = 10; -- filter, will return only movies that were rented for 10 days at the store Mike works



-- 6. Alphabetically list actors who appeared in the movie with the largest cast of actors.
		-- need to create CTE of movie cast counts 
			-- select film_id
			-- no need to join anything since just comparing count of actors in movie 
				-- need film_id and cast count
            -- need to combine actor with film_actor and movie_cast_counts
				-- chain broken if there is no link with primary keys, everything has to be connected
					-- film_actor and nd movie_cast_counts have foreign keys 
				-- need actor name
				-- need to assort actors names alphabetically  
		-- select to show query results in grid

WITH movie_cast_counts AS ( -- create CTE
    SELECT fa.film_id, COUNT(fa.actor_id) AS cast_count -- alias and counts actors in a film
    FROM film_actor fa -- universal set
    GROUP BY fa.film_id -- filter by film_id
    ORDER BY cast_count DESC -- greatest to smallest
    LIMIT 1 -- will only show film with largest cast
),
actors_in_largest_cast_movie AS ( -- using CTE created above
    SELECT a.first_name, a.last_name
    FROM actor a -- universal set
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    JOIN movie_cast_counts mcc ON fa.film_id = mcc.film_id
    ORDER BY a.first_name, a.last_name -- how data is organized in grid, alphabetically
)
SELECT first_name, last_name
FROM actors_in_largest_cast_movie;
