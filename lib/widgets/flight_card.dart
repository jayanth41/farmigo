      const SizedBox(height: 12),

      /// Airline + Price
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.flight_takeoff, size: 18, color: Colors.blueGrey),
              SizedBox(width: 6),
              Text(
                "Flight",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            offer.displayPrice,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),

      /// Route + Duration Row
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.route, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                "${offer.origin} → ${offer.destination}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                offer.duration ?? "--",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),

      const SizedBox(height: 10),

      /// Flight Timeline
      Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.origin,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Departure",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),

          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Icon(Icons.flight, size: 18, color: Colors.grey),
                  Expanded(child: Divider()),
                ],
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                offer.destination,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Arrival",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),

      const SizedBox(height: 14),

      /// Offer ID