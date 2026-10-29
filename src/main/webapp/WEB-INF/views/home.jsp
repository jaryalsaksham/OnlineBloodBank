<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="Home"/>
    <jsp:param name="nav" value="home"/>
</jsp:include>

<section class="hero">
    <div class="container">
        <h1>Donate blood. Save a life today.</h1>
        <p>A simple online platform that connects blood donors, patients and the blood bank. Register as a donor,
           search for donors, check live blood availability or raise an emergency request in minutes.</p>
        <div class="btn-row">
            <a class="btn btn-light" href="${ctx}/register">Become a Donor</a>
            <a class="btn btn-outline" style="color:#fff;border-color:#fff" href="${ctx}/request-blood">Request Blood</a>
        </div>
    </div>
</section>

<div class="container hero-stats">
    <div class="grid grid-4">
        <div class="card stat"><div class="num"><c:out value="${statDonors}"/></div><div class="lbl">Registered donors</div></div>
        <div class="card stat"><div class="num"><c:out value="${statUnits}"/></div><div class="lbl">Units in stock</div></div>
        <div class="card stat"><div class="num"><c:out value="${statDonations}"/></div><div class="lbl">Donations recorded</div></div>
        <div class="card stat"><div class="num"><c:out value="${statFulfilled}"/></div><div class="lbl">Requests fulfilled</div></div>
    </div>
</div>

<section class="section">
    <div class="container">
        <h2>Blood availability</h2>
        <p class="muted">Live stock by blood group. Groups marked <span class="badge badge-low">Low</span> need donors urgently.</p>
        <div class="grid grid-4">
            <c:forEach var="s" items="${stock}">
                <div class="card stock-card">
                    <span class="units"><c:out value="${s.units}"/> <span class="muted small">units</span></span>
                    <div class="group"><c:out value="${s.bloodGroup}"/></div>
                    <div class="bar"><span class="${s.level}" style="width:${s.percent}%"></span></div>
                    <c:choose>
                        <c:when test="${s.level == 'empty'}"><span class="badge badge-empty">Out of stock</span></c:when>
                        <c:when test="${s.level == 'low'}"><span class="badge badge-low">Low</span></c:when>
                        <c:otherwise><span class="badge badge-ok">Available</span></c:otherwise>
                    </c:choose>
                </div>
            </c:forEach>
        </div>
    </div>
</section>

<section class="section">
    <div class="container">
        <h2>How it works</h2>
        <div class="grid grid-3">
            <div class="card step"><div class="n">1</div><h3>Register</h3>
                <p class="muted">Create a donor account with your blood group and city. It takes less than two minutes.</p></div>
            <div class="card step"><div class="n">2</div><h3>Donate</h3>
                <p class="muted">Visit the blood bank or a camp. The administrator records your donation and your stock units are added.</p></div>
            <div class="card step"><div class="n">3</div><h3>Save lives</h3>
                <p class="muted">Patients and hospitals raise requests online; the blood bank approves them against live stock.</p></div>
        </div>
    </div>
</section>

<section class="section">
    <div class="container grid grid-2">
        <div>
            <h2>Who can donate?</h2>
            <div class="card">
                <ul>
                    <li>Age between <strong>18 and 65 years</strong>.</li>
                    <li>At least <strong>90 days</strong> since your last whole-blood donation.</li>
                    <li>In good general health on the day of donation.</li>
                    <li>Not currently ill, or on medication that prevents donation.</li>
                </ul>
                <p class="muted small">The system checks the age and the 90-day gap automatically. The final medical screening is always done by the blood bank staff.</p>
            </div>
        </div>
        <div>
            <h2>Blood group compatibility</h2>
            <div class="table-wrap">
                <table class="compat">
                    <thead><tr><th>Group</th><th>Can donate to</th><th>Can receive from</th></tr></thead>
                    <tbody>
                    <tr><td>A+</td><td>A+, AB+</td><td>A+, A-, O+, O-</td></tr>
                    <tr><td>A-</td><td>A+, A-, AB+, AB-</td><td>A-, O-</td></tr>
                    <tr><td>B+</td><td>B+, AB+</td><td>B+, B-, O+, O-</td></tr>
                    <tr><td>B-</td><td>B+, B-, AB+, AB-</td><td>B-, O-</td></tr>
                    <tr><td>AB+</td><td>AB+</td><td>All groups</td></tr>
                    <tr><td>AB-</td><td>AB+, AB-</td><td>A-, B-, AB-, O-</td></tr>
                    <tr><td>O+</td><td>O+, A+, B+, AB+</td><td>O+, O-</td></tr>
                    <tr><td>O-</td><td>All groups</td><td>O-</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</section>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
