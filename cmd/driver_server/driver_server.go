package main

import (
	"bufio"
	"flag"
	"log"
	"net/http"
	"os"
	"strings"
)

var nvidiaPathPrefix = flag.String("nvidia-path", "/usr/local/nvidia", "Path that contains the nvidia libraries and drivers")
var listenAddr = flag.String("listen-addr", ":8080", "Address where to start the server")

func main() {
	flag.Parse()

	cacheFilePath := *nvidiaPathPrefix + "/.cache"
	log.Printf("Reading cache file at %q", cacheFilePath)
	f, err := os.Open(cacheFilePath)
	if err != nil {
		log.Fatalf("Can't open file %q: %v", cacheFilePath, err)
	}
	defer f.Close()

	var buildID string
	var nvidiaDriverVersion string

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		pair := strings.SplitN(line, "=", 2)

		switch pair[0] {
		case "CACHE_BUILD_ID":
			buildID = pair[1]
		case "CACHE_NVIDIA_DRIVER_VERSION":
			nvidiaDriverVersion = pair[1]
		default:
			log.Printf("Unknown line: %v", line)
		}
	}

	if err := scanner.Err(); err != nil {
		log.Fatalf("Error scanning %q: %v", cacheFilePath, err)
	}

	tarFilePath := *nvidiaPathPrefix + "/nvidia.tgz"
	urlPath := "/" + buildID + "/" + nvidiaDriverVersion

	mux := http.NewServeMux()
	mux.HandleFunc(urlPath, func(w http.ResponseWriter, req *http.Request) {
		http.ServeFile(w, req, tarFilePath)
	})

	log.Printf("Serving %q at %v", tarFilePath, *listenAddr+urlPath)
	err = http.ListenAndServe(*listenAddr, mux)
	log.Fatalf("http server failed: %v", err)
}
