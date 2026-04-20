#!/bin/bash
# DESC: Gateway API - HTTPRoute with header-based routing
# NODE: cka7968

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

NS="project-r500"
OUT_DIR="/opt/course/13"

print_header "Q13 | Gateway API - HTTPRoute"

print_section "Task"
echo -e "  ${BOLD}1.${RESET} Create HTTPRoute ${CYAN}traffic-director${RESET} replicating existing Ingress routes:"
echo -e "     /desktop → web-desktop service"
echo -e "     /mobile  → web-mobile service"
echo -e "  ${BOLD}2.${RESET} Add path ${CYAN}/auto${RESET} with header-based routing:"
echo -e "     User-Agent: mobile → web-mobile"
echo -e "     (otherwise)        → web-desktop"
echo ""
echo -e "  ${BOLD}Test URLs:${RESET}"
print_cmd "curl r500.gateway:30080/desktop"
print_cmd "curl r500.gateway:30080/mobile"
print_cmd "curl r500.gateway:30080/auto -H 'User-Agent: mobile'"
print_cmd "curl r500.gateway:30080/auto"
echo ""

print_section "Environment Setup"
setup_output_dir "$OUT_DIR"

# Create the ingress.yaml reference file
cat > "$OUT_DIR/ingress.yaml" <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: traffic-director
spec:
  ingressClassName: nginx
  rules:
    - host: r500.gateway
      http:
        paths:
          - backend:
              service:
                name: web-desktop
                port:
                  number: 80
            path: /desktop
            pathType: Prefix
          - backend:
              service:
                name: web-mobile
                port:
                  number: 80
            path: /mobile
            pathType: Prefix
EOF

print_success "Reference Ingress yaml created at: $OUT_DIR/ingress.yaml"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Inspect existing Gateway:${RESET}"
print_cmd "k -n $NS get gateway"
print_cmd "k -n $NS get gateway main -oyaml"
print_cmd "k get crd | grep gateway"
echo ""

echo -e "${BOLD}Step 2 - Create the HTTPRoute:${RESET}"
print_cmd "vim 13_httproute.yaml"
echo ""

cat <<'EOF'
  # 13_httproute.yaml
  apiVersion: gateway.networking.k8s.io/v1
  kind: HTTPRoute
  metadata:
    name: traffic-director
    namespace: project-r500
  spec:
    parentRefs:
      - name: main          # reference the existing Gateway
    hostnames:
      - "r500.gateway"
    rules:
      - matches:
          - path:
              type: PathPrefix
              value: /desktop
        backendRefs:
          - name: web-desktop
            port: 80
      - matches:
          - path:
              type: PathPrefix
              value: /mobile
        backendRefs:
          - name: web-mobile
            port: 80
      # /auto with User-Agent: mobile → web-mobile  (check BOTH path AND header)
      - matches:
          - path:
              type: PathPrefix
              value: /auto
            headers:
            - type: Exact
              name: user-agent
              value: mobile
        backendRefs:
          - name: web-mobile
            port: 80
      # /auto fallback → web-desktop  (must come AFTER the mobile rule)
      - matches:
          - path:
              type: PathPrefix
              value: /auto
        backendRefs:
          - name: web-desktop
            port: 80
EOF
echo ""

print_cmd "k apply -f 13_httproute.yaml"
echo ""

print_section "Verify"
print_cmd "k -n $NS get httproute"
print_cmd "curl r500.gateway:30080/desktop"
print_cmd "curl r500.gateway:30080/mobile"
print_cmd "curl -H 'User-Agent: mobile' r500.gateway:30080/auto"
print_cmd "curl r500.gateway:30080/auto"
echo ""

print_section "Key Concept: AND vs OR in matches"
echo ""
echo -e "  ${GREEN}Correct${RESET} (path AND header must both match):"
echo "    - matches:"
echo "        - path: {value: /auto}      ← same list item"
echo "          headers:                   ← same list item = AND"
echo "          - name: user-agent"
echo ""
echo -e "  ${RED}Wrong${RESET} (path OR header):"
echo "    - matches:"
echo "        - path: {value: /auto}      ← item 1"
echo "        - headers:                  ← item 2 = OR"
echo "          - name: user-agent"
echo ""

print_hint "Rule ORDER matters — mobile rule must come before the desktop catch-all for /auto"
divider
